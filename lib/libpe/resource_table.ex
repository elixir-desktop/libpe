defmodule LibPE.ResourceTable do
  @moduledoc """
    Parses windows resource tables

    By convention these are always three levels:

      Type > Name > Language
  """
  alias LibPE.ResourceTable
  import Bitwise

  defstruct characteristics: 0,
            timestamp: 0,
            major_version: 0,
            minor_version: 0,
            entries: []

  defmodule DirEntry do
    @moduledoc false
    defstruct name: nil,
              entry: nil,
              raw_entry: 0,
              raw_name: 0
  end

  defmodule DataBlob do
    @moduledoc false
    defstruct data_rva: 0,
              data: nil,
              codepage: 0,
              reserved: 0
  end

  defmodule EncodeContext do
    @moduledoc false
    defstruct [
      :image_offset,
      :names,
      :tables,
      :output,
      :data_entries
    ]

    def append(%EncodeContext{output: output} = ex, data) do
      %EncodeContext{ex | output: output <> data}
    end
  end

  def parse(resources, image_offset) do
    parse(resources, resources, image_offset)
  end

  defp parse(
         <<characteristics::little-size(32), timestamp::little-size(32),
           major_version::little-size(16), minor_version::little-size(16),
           number_of_name_entries::little-size(16), number_of_id_entries::little-size(16),
           rest::binary>>,
         resources,
         image_offset
       ) do
    {entries, _rest} =
      List.duplicate(%DirEntry{}, number_of_name_entries + number_of_id_entries)
      |> Enum.map_reduce(rest, fn _entry, rest ->
        parse_entry(rest, resources, image_offset)
      end)

    %ResourceTable{
      characteristics: characteristics,
      timestamp: timestamp,
      major_version: major_version,
      minor_version: minor_version,
      entries: entries
    }
  end

  @doc """
    Allows updating a resources. At the moment this call is destructive as it does
    not allows defining more than one name or language per resource entry.
    Each defined resource entry set with `set_resource` will have it's PE name
    set to `1` and it's language to the provided language code by default `1033`

    Example:

    > LibPE.ResourceTable.set_resource(table, "RT_MANIFEST", manifest)

    Known resources types are:

    ```
      {"RT_ACCELERATOR", 9, "Accelerator table."},
      {"RT_ANICURSOR", 21, "Animated cursor."},
      {"RT_ANIICON", 22, "Animated icon."},
      {"RT_BITMAP", 2, "Bitmap resource."},
      {"RT_CURSOR", 1, "Hardware-dependent cursor resource."},
      {"RT_DIALOG", 5, "Dialog box."},
      {"RT_DLGINCLUDE", 17,
       "Allows a resource editing tool to associate a string with an .rc file. Typically, the string is the name of the header file that provides symbolic names. The resource compiler parses the string but otherwise ignores the value. For example,"},
      {"RT_FONT", 8, "Font resource."},
      {"RT_FONTDIR", 7, "Font directory resource."},
      {"RT_GROUP_CURSOR", 12, "Hardware-independent cursor resource."},
      {"RT_GROUP_ICON", 14, "Hardware-independent icon resource."},
      {"RT_HTML", 23, "HTML resource."},
      {"RT_ICON", 3, "Hardware-dependent icon resource."},
      {"RT_MANIFEST", 24, "Side-by-Side Assembly Manifest."},
      {"RT_MENU", 4, "Menu resource."},
      {"RT_MESSAGETABLE", 11, "Message-table entry."},
      {"RT_PLUGPLAY", 19, "Plug and Play resource."},
      {"RT_RCDATA", 10, "Application-defined resource (raw data)."},
      {"RT_STRING", 6, "String-table entry."},
      {"RT_VERSION", 16, "Version resource."},
      {"RT_VXD", 20, "VXD."}
    ```

  """
  def set_resource(
        table = %ResourceTable{entries: entries},
        resource_type,
        entry_or_data,
        codepage \\ 0,
        language \\ 1033
      ) do
    type = LibPE.ResourceTypes.encode(resource_type)
    if type == nil, do: raise("ResourceType #{resource_type} is unknown")
    page = LibPE.Codepage.encode(codepage)
    if page == nil, do: raise("Codepage #{codepage} is unknown")
    lang = LibPE.Language.encode(language)
    if lang == nil, do: raise("Language #{language} is unknown")

    target_entry =
      case entry_or_data do
        bin when is_binary(bin) ->
          %DirEntry{name: lang, entry: %DataBlob{codepage: page, data: bin}}

        %DirEntry{} ->
          entry_or_data
      end

    entry =
      Enum.find(entries, %DirEntry{name: type}, fn %DirEntry{name: name} -> type == name end)

    entry = %DirEntry{
      entry
      | entry: %ResourceTable{
          entries: [%DirEntry{name: 1, entry: %ResourceTable{entries: [target_entry]}}]
        }
    }

    idx = Enum.find_index(entries, fn %DirEntry{name: name} -> type == name end)

    entries =
      if idx == nil do
        sorted_entries(%ResourceTable{table | entries: entries ++ [entry]})
      else
        List.update_at(entries, idx, fn _ -> entry end)
      end

    %ResourceTable{table | entries: entries}
  end

  def get_resource(%ResourceTable{entries: entries}, resource_type) do
    type = LibPE.ResourceTypes.encode(resource_type)
    if type == nil, do: raise("ResourceType #{resource_type} is unknown")

    case Enum.find(entries, fn %DirEntry{name: name} -> type == name end) do
      nil ->
        nil

      %DirEntry{
        entry: %ResourceTable{
          entries: [
            %DirEntry{
              entry: %ResourceTable{
                entries: [
                  entry = %DirEntry{name: _lang, entry: %DataBlob{codepage: _page, data: _data}}
                ]
              }
            }
          ]
        }
      } ->
        entry
    end
  end

  def encode(resource_table, image_offset) do
    context = %EncodeContext{
      image_offset: image_offset,
      tables: %{},
      names: %{},
      output: "",
      data_entries: []
    }

    # First run to establish offsets and fulll size
    context =
      do_encode(resource_table, context)
      |> encode_tables(resource_table)
      |> encode_data_entries()
      |> encode_names()
      |> encode_data_leaves()
      |> Map.put(:output, "")

    # IO.puts("ROUND#2")
    # Second run now inserting all correct offsets
    context =
      do_encode(resource_table, context)
      |> encode_tables(resource_table)
      |> encode_data_entries()
      |> encode_names()
      |> encode_data_leaves()

    context.output
  end

  @high 0x80000000
  defp do_encode(
         %ResourceTable{
           characteristics: characteristics,
           timestamp: timestamp,
           major_version: major_version,
           minor_version: minor_version
         } = table,
         %EncodeContext{} = context
       ) do
    entries = sorted_entries(table)
    number_of_id_entries = Enum.count(entries, fn %DirEntry{name: name} -> is_integer(name) end)
    number_of_name_entries = length(entries) - number_of_id_entries

    context =
      EncodeContext.append(
        context,
        <<characteristics::little-size(32), timestamp::little-size(32),
          major_version::little-size(16), minor_version::little-size(16),
          number_of_name_entries::little-size(16), number_of_id_entries::little-size(16)>>
      )

    Enum.reduce(entries, context, fn entry, context -> encode_entry(entry, context) end)
  end

  defp sorted_entries(%ResourceTable{entries: entries}) do
    {name_entries, id_entries} =
      Enum.reduce(entries, {[], []}, fn entry = %DirEntry{}, {names, ids} ->
        if is_integer(entry.name) do
          {names, ids ++ [entry]}
        else
          {names ++ [entry], ids}
        end
      end)

    Enum.sort(name_entries, fn a, b -> a.name < b.name end) ++
      Enum.sort(id_entries, fn a, b -> a.name < b.name end)
  end

  defp encode_tables(context, %ResourceTable{} = table) do
    # Reducing recursively other DirectoryTables
    entries = sorted_entries(table)

    context =
      Enum.reduce(entries, context, fn %DirEntry{entry: entry},
                                       context = %EncodeContext{tables: tables, output: output} ->
        case entry do
          dir = %ResourceTable{} ->
            offset = byte_size(output) ||| @high
            # IO.puts("table offset: #{byte_size(output)}")
            context = %EncodeContext{context | tables: Map.put(tables, dir, offset)}
            do_encode(dir, context)

          _other ->
            context
        end
      end)

    Enum.reduce(entries, context, fn %DirEntry{entry: entry}, context ->
      case entry do
        table = %ResourceTable{} -> encode_tables(context, table)
        _other -> context
      end
    end)
  end

  defp parse_entry(
         <<raw_name::little-size(32), raw_entry::little-size(32), rest::binary>>,
         resources,
         image_offset
       ) do
    name =
      if (raw_name &&& @high) == 0 do
        raw_name
      else
        name_offset = raw_name &&& bnot(@high)

        <<_::binary-size(name_offset), length::little-size(16), name::binary-size(length),
          name2::binary-size(length), _rest::binary>> = resources

        :unicode.characters_to_binary(name <> name2, {:utf16, :little}, :utf8)
      end

    entry =
      if (raw_entry &&& @high) == @high do
        entry_offset = raw_entry &&& bnot(@high)
        <<_::binary-size(entry_offset), data::binary>> = resources
        parse(data, resources, image_offset)
      else
        parse_data_entry(raw_entry, resources, image_offset)
      end

    {%DirEntry{
       name: name,
       entry: entry,
       raw_name: raw_name &&& bnot(@high),
       raw_entry: raw_entry &&& bnot(@high)
     }, rest}
  end

  defp encode_entry(
         %DirEntry{
           name: name,
           raw_name: raw_name,
           entry: entry,
           raw_entry: raw_entry
         },
         %EncodeContext{
           names: names,
           tables: tables,
           data_entries: data_entries
         } = context
       ) do
    {raw_name, context} =
      cond do
        is_integer(name) -> {name, context}
        names[name] != nil -> {names[name], context}
        true -> {raw_name, %EncodeContext{context | names: Map.put(names, name, 0)}}
      end

    {raw_entry, context} =
      case entry do
        dir = %ResourceTable{} ->
          if tables[dir] != nil do
            {tables[dir], context}
          else
            {raw_entry, %EncodeContext{context | tables: Map.put(tables, dir, 0)}}
          end

        %DataBlob{data: blob, codepage: codepage} ->
          key = %DataBlob{data: blob, codepage: codepage}

          if fetch(data_entries, key) != nil do
            {fetch!(data_entries, key).offset, context}
          else
            {raw_entry,
             %EncodeContext{
               context
               | data_entries: put(data_entries, key, %{data_rva: 0, offset: 0})
             }}
          end
      end

    EncodeContext.append(context, <<raw_name::little-size(32), raw_entry::little-size(32)>>)
  end

  defp encode_names(%EncodeContext{names: names} = context) do
    Enum.sort(names)
    |> Enum.reduce(context, fn {name, _offset},
                               context = %EncodeContext{output: output, names: names} ->
      output = output <> String.duplicate(<<0>>, rem(byte_size(output), 2))
      offset = byte_size(output) ||| @high
      # IO.puts("name offset #{byte_size(output)}")
      names = Map.put(names, name, offset)
      bin = :unicode.characters_to_binary(name, :utf8, {:utf16, :little})
      output = output <> <<String.length(name)::little-size(16), bin::binary>>

      %EncodeContext{context | names: names, output: output}
    end)
  end

  defp parse_data_entry(entry_offset, resources, image_offset) do
    <<_::binary-size(entry_offset), data_rva::little-size(32), size::little-size(32),
      codepage::little-size(32), reserved::little-size(32), _rest::binary>> = resources

    data = binary_part(resources, data_rva - image_offset, size)

    %DataBlob{
      data_rva: data_rva,
      data: data,
      codepage: codepage,
      reserved: reserved
    }
  end

  defp encode_data_entries(%EncodeContext{data_entries: data_entries} = context) do
    Enum.reduce(data_entries, context, fn {%DataBlob{codepage: codepage, data: blob} = key,
                                           %{data_rva: data_rva}},
                                          context = %EncodeContext{
                                            output: output,
                                            data_entries: data_entries
                                          } ->
      # output = output <> String.duplicate(<<0>>, rem(byte_size(output), 2))
      offset = byte_size(output)
      # IO.puts("blob offset = #{offset}")
      size = byte_size(blob)
      reserved = 0

      output =
        output <>
          <<data_rva::little-size(32), size::little-size(32), codepage::little-size(32),
            reserved::little-size(32)>>

      data_entries = put(data_entries, key, %{offset: offset, data_rva: data_rva})
      %EncodeContext{context | data_entries: data_entries, output: output}
    end)
  end

  defp encode_data_leaves(
         %EncodeContext{data_entries: entries, image_offset: image_offset} = context
       ) do
    # some binaries do this, others don't
    context = EncodeContext.append(context, <<0::little-size(32)>>)

    entries
    |> Enum.reduce(context, fn {%DataBlob{data: blob} = key, offsets},
                               context = %EncodeContext{
                                 output: output,
                                 data_entries: entries
                               } ->
      output = LibPE.binary_pad_trailing(output, ceil(byte_size(output) / 8) * 8)
      data_rva = byte_size(output) + image_offset
      output = output <> blob
      output = LibPE.binary_pad_trailing(output, ceil(byte_size(output) / 8) * 8)
      entries = put(entries, key, %{offsets | data_rva: data_rva})
      %EncodeContext{context | data_entries: entries, output: output}
    end)
  end

  def dump(data, opts \\ []) do
    if data == nil do
      IO.puts("NO RESOURCE TABLE")
    else
      dump(data, 0, opts)
    end
  end

  defp dump(
         %ResourceTable{
           characteristics: _characteristics,
           timestamp: _timestamp,
           major_version: _major_version,
           minor_version: _minor_version,
           entries: entries
         },
         level,
         opts
       ) do
    # Those values are always 0 it seems
    # IO.puts(
    #   "#{dup(level)} flags: #{characteristics}, timestamp: #{timestamp}, version: #{major_version}:#{
    #     minor_version
    #   }"
    # )

    Enum.each(entries, fn entry ->
      dump(entry, level, opts)
    end)
  end

  defp dump(%DirEntry{name: name, entry: entry}, level, opts) do
    label =
      case level do
        0 -> "TYPE: #{inspect(LibPE.ResourceTypes.decode(name))}"
        1 -> "NAME: #{inspect(name)}"
        2 -> "LANG: #{inspect(LibPE.Language.decode(name))}"
        _other -> inspect(name)
      end

    opts =
      if level == 0 do
        Keyword.put(opts, :type, name)
      else
        opts
      end

    IO.puts("#{dup(level)} DIRENTRY: #{label}")
    dump(entry, level + 1, opts)
  end

  defp dump(%DataBlob{data_rva: _data_rva, data: data, codepage: codepage}, level, opts) do
    IO.puts(
      "#{dup(level)} DATA size: #{byte_size(data)}, codepage: #{inspect(LibPE.Codepage.decode(codepage))}"
    )

    cond do
      Keyword.get(opts, :type, nil) == 16 ->
        version_info = LibPE.VersionInfo.decode(data)
        IO.puts("#{dup(level + 1)} Version Params =>")

        for {key, value} <- version_info.strings do
          IO.puts("#{dup(level + 2)} #{String.pad_trailing(key, 20)} = #{value}")
        end

        IO.puts("#{dup(level + 1)} Version Flags =>")

        for {key, value} <- version_info.version_info do
          key = Atom.to_string(key)
          IO.puts("#{dup(level + 2)} :#{String.pad_trailing(key, 20)} = #{inspect(value)}")
        end

      Keyword.get(opts, :values, false) ->
        value =
          if String.printable?(data) do
            inspect(data, limit: :infinity)
          else
            "0x" <> Base.encode16(data, case: :lower)
          end

        IO.puts("#{dup(level + 1)} VALUE: #{value}")

      true ->
        IO.puts("#{dup(level + 1)} VALUE: #{inspect(data)}")
        :ok
    end
  end

  defp dup(level) do
    String.duplicate("  ", level)
  end

  defp put(list, key, value) do
    List.keystore(list, key, 0, {key, value})
  end

  defp fetch(list, key) do
    {^key, value} = List.keyfind(list, key, 0, {key, nil})
    value
  end

  defp fetch!(list, key) do
    {^key, value} = List.keyfind(list, key, 0)
    value
  end
end

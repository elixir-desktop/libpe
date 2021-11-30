defmodule LibPE.ResourceDirectoryTable do
  @moduledoc """
    Parses windows resource tables

    By convention these are always three levels:

      Type > Name > Language
  """
  alias LibPE.ResourceDirectoryTable
  use Bitwise

  defstruct [
    :characteristics,
    :timestamp,
    :major_version,
    :minor_version,
    :entries
  ]

  defmodule DirEntry do
    defstruct [
      :name,
      :entry,
      :raw_entry,
      :raw_name
    ]
  end

  defmodule DataEntry do
    defstruct [
      :data_rva,
      :size,
      :data,
      :codepage,
      :reserved
    ]
  end

  defmodule EncodeContext do
    defstruct [
      :image_offset,
      :names,
      :tables,
      :output,
      :data_entries,
      :data_leaves
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

    %ResourceDirectoryTable{
      characteristics: characteristics,
      timestamp: timestamp,
      major_version: major_version,
      minor_version: minor_version,
      entries: entries
    }
  end

  def encode(resource_table, image_offset) do
    context = %EncodeContext{
      image_offset: image_offset,
      tables: %{},
      names: %{},
      output: "",
      data_entries: %{},
      data_leaves: %{}
    }

    # First run to establish offsets and fulll size
    context =
      do_encode(resource_table, context)
      |> encode_names()
      |> encode_data_entries()
      |> encode_data_leaves()
      |> Map.put(:output, "")

    IO.puts("ROUND#2")
    # Second run now inserting all correct offsets
    context =
      do_encode(resource_table, context)
      |> encode_names()
      |> encode_data_entries()
      |> encode_data_leaves()

    context.output
  end

  @high 0x80000000
  defp do_encode(
         %ResourceDirectoryTable{
           characteristics: characteristics,
           timestamp: timestamp,
           major_version: major_version,
           minor_version: minor_version,
           entries: entries
         },
         context = %EncodeContext{}
       ) do
    {name_entries, id_entries} =
      Enum.reduce(entries, {[], []}, fn entry = %DirEntry{}, {names, ids} ->
        if is_integer(entry.name) do
          {names, ids ++ [entry]}
        else
          {names ++ [entry], ids}
        end
      end)

    number_of_name_entries = length(name_entries)
    number_of_id_entries = length(id_entries)

    context =
      EncodeContext.append(
        context,
        <<characteristics::little-size(32), timestamp::little-size(32),
          major_version::little-size(16), minor_version::little-size(16),
          number_of_name_entries::little-size(16), number_of_id_entries::little-size(16)>>
      )

    entries =
      Enum.sort(name_entries, fn a, b -> a.name < b.name end) ++
        Enum.sort(id_entries, fn a, b -> a.name < b.name end)

    context = Enum.reduce(entries, context, fn entry, context -> encode_entry(entry, context) end)

    # Reducing recursively other DirectoryTables
    Enum.reduce(entries, context, fn %DirEntry{entry: entry},
                                     context = %EncodeContext{tables: tables, output: output} ->
      case entry do
        dir = %ResourceDirectoryTable{} ->
          offset = byte_size(output) ||| @high
          context = %EncodeContext{context | tables: Map.put(tables, dir, offset)}
          do_encode(dir, context)

        _other ->
          context
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
       raw_name: raw_name,
       raw_entry: raw_entry
     }, rest}
  end

  defp encode_entry(
         %DirEntry{
           name: name,
           raw_name: raw_name,
           entry: entry,
           raw_entry: raw_entry
         },
         context = %EncodeContext{
           names: names,
           tables: tables,
           data_entries: data_entries,
           data_leaves: data_leaves
         }
       ) do
    {raw_name, context} =
      cond do
        is_integer(name) -> {name, context}
        names[name] != nil -> {names[name], context}
        true -> {raw_name, %EncodeContext{context | names: Map.put(names, name, 0)}}
      end

    {raw_entry, context} =
      case entry do
        dir = %ResourceDirectoryTable{} ->
          if tables[dir] != nil do
            {tables[dir], context}
          else
            {raw_entry, %EncodeContext{context | tables: Map.put(tables, dir, 0)}}
          end

        %DataEntry{data: blob} ->
          if data_entries[blob] != nil do
            {data_entries[blob], context}
          else
            {raw_entry,
             %EncodeContext{
               context
               | data_entries: Map.put(data_entries, blob, 0),
                 data_leaves: Map.put(data_leaves, blob, 0)
             }}
          end
      end

    EncodeContext.append(context, <<raw_name::little-size(32), raw_entry::little-size(32)>>)
  end

  defp encode_names(%EncodeContext{names: names} = context) do
    Enum.reduce(names, context, fn {name, _offset},
                                   context = %EncodeContext{output: output, names: names} ->
      output = output <> String.duplicate(<<0>>, rem(byte_size(output), 2))
      offset = byte_size(output) ||| @high
      names = Map.put(names, name, offset)
      bin = :unicode.characters_to_binary(name, :utf8, {:utf16, :little})
      output = output <> <<String.length(name)::little-size(16), bin::binary>>

      %EncodeContext{context | names: names, output: output}
    end)
  end

  defp parse_data_entry(entry_offset, resources, image_offset) do
    IO.inspect("parse_data_entry(#{entry_offset}, #{byte_size(resources)})")

    <<_::binary-size(entry_offset), data_rva::little-size(32), size::little-size(32),
      codepage::little-size(32), reserved::little-size(32), _rest::binary>> = resources

    data = binary_part(resources, data_rva - image_offset, size)

    %DataEntry{
      data_rva: data_rva,
      size: size,
      data: data,
      codepage: codepage,
      reserved: reserved
    }
  end

  defp encode_data_entries(
         %EncodeContext{data_entries: data_entries, data_leaves: leaves} = context
       ) do
    Enum.reduce(data_entries, context, fn {blob, _offset},
                                          context = %EncodeContext{
                                            output: output,
                                            data_entries: data_entries
                                          } ->
      # output = output <> String.duplicate(<<0>>, rem(byte_size(output), 2))
      offset = byte_size(output)
      IO.puts("blob offset = #{offset}")
      data_rva = Map.fetch!(leaves, blob)
      size = byte_size(blob)
      codepage = 0
      reserved = 0

      output =
        output <>
          <<data_rva::little-size(32), size::little-size(32), codepage::little-size(32),
            reserved::little-size(32)>>

      data_entries = Map.put(data_entries, blob, offset)
      %EncodeContext{context | data_entries: data_entries, output: output}
    end)
  end

  defp encode_data_leaves(
         %EncodeContext{data_leaves: leaves, image_offset: image_offset} = context
       ) do
    Enum.reduce(leaves, context, fn {blob, _offset},
                                    context = %EncodeContext{
                                      output: output,
                                      data_leaves: leaves
                                    } ->
      # output = output <> String.duplicate(<<0>>, rem(byte_size(output), 2))
      data_rva = byte_size(output) + image_offset
      output = output <> blob
      leaves = Map.put(leaves, blob, data_rva)
      %EncodeContext{context | data_leaves: leaves, output: output}
    end)
  end

  def dump(data) do
    dump(data, 0)
  end

  defp dump(
         %ResourceDirectoryTable{
           characteristics: _characteristics,
           timestamp: _timestamp,
           major_version: _major_version,
           minor_version: _minor_version,
           entries: entries
         },
         level
       ) do
    # Those values are always 0 it seems
    # IO.puts(
    #   "#{dup(level)} flags: #{characteristics}, timestamp: #{timestamp}, version: #{major_version}:#{
    #     minor_version
    #   }"
    # )

    Enum.each(entries, fn entry ->
      dump(entry, level)
    end)
  end

  defp dump(%DirEntry{name: name, entry: entry}, level) do
    label =
      case level do
        0 -> "TYPE: #{inspect(LibPE.ResourceTypes.decode(name))}"
        1 -> "NAME: #{inspect(name)}"
        2 -> "LANG: #{inspect(LibPE.Language.decode(name))}"
        _other -> inspect(name)
      end

    IO.puts("#{dup(level)} DIRENTRY: #{label}")
    dump(entry, level + 1)
  end

  defp dump(%DataEntry{data_rva: _data_rva, size: size, data: _data, codepage: codepage}, level) do
    IO.puts("#{dup(level)} DATA size: #{size}, codepage: #{codepage}")
  end

  defp dup(level) do
    String.duplicate("  ", level)
  end
end

defmodule LibPE.ResourceDirectoryTable do
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
      :id,
      :offset,
      :entry
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

  def parse(resources) do
    parse(resources, resources)
  end

  defp parse(
         <<characteristics::little-size(32), timestamp::little-size(32),
           major_version::little-size(16), minor_version::little-size(16),
           number_of_name_entries::little-size(16), number_of_id_entries::little-size(16),
           rest::binary>>,
         full
       ) do
    {entries, _rest} =
      List.duplicate(%DirEntry{}, number_of_name_entries + number_of_id_entries)
      |> Enum.map_reduce(rest, fn _entry, rest ->
        parse_entry(rest, full)
      end)

    %ResourceDirectoryTable{
      characteristics: characteristics,
      timestamp: timestamp,
      major_version: major_version,
      minor_version: minor_version,
      entries: entries
    }
  end

  @high 0x80000000
  defp parse_entry(
         <<name::little-size(32), entry_offset::little-size(32), rest::binary>>,
         full
       ) do
    id =
      if (name &&& @high) == 0 do
        name
      else
        name_offset = name &&& bnot(@high)

        <<_::binary-size(name_offset), length::little-size(16), name::binary-size(length),
          name2::binary-size(length), _rest::binary>> = full

        :unicode.characters_to_binary(name <> name2, {:utf16, :little}, :utf8)
      end

    entry =
      if (entry_offset &&& @high) == @high do
        entry_offset = entry_offset &&& bnot(@high)
        <<_::binary-size(entry_offset), data::binary>> = full
        parse(data, full)
      else
        parse_data_entry(entry_offset, full)
      end

    {%DirEntry{
       id: id,
       offset: byte_size(full) - byte_size(rest),
       entry: entry
     }, rest}
  end

  defp parse_data_entry(entry_offset, full) do
    <<_::binary-size(entry_offset), data_rva::little-size(32), size::little-size(32),
      codepage::little-size(32), reserved::little-size(32), _rest::binary>> = full

    # data = binary_part(full, data_rva, size)

    %DataEntry{
      data_rva: data_rva,
      size: size,
      # data: data,
      codepage: codepage,
      reserved: reserved
    }
  end

  def dump(data) do
    dump(data, 0)
  end

  defp dump(
         %ResourceDirectoryTable{
           characteristics: characteristics,
           timestamp: timestamp,
           major_version: major_version,
           minor_version: minor_version,
           entries: entries
         },
         level
       ) do
    IO.puts(
      "#{dup(level)} flags: #{characteristics}, timestamp: #{timestamp}, version: #{major_version}:#{
        minor_version
      }"
    )

    Enum.each(entries, fn entry ->
      dump(entry, level + 1)
    end)
  end

  defp dump(%DirEntry{id: id, offset: _offset, entry: entry}, level) do
    IO.puts("#{dup(level)} DIRENTRY: #{id}")
    dump(entry, level + 1)
  end

  defp dump(%DataEntry{data_rva: _data_rva, size: size, data: _data, codepage: codepage}, level) do
    IO.puts("#{dup(level)} DATA size: #{size}, codepage: #{codepage}")
  end

  defp dup(level) do
    String.duplicate("  ", level)
  end
end

# Temporary dump of rcedit golden icon resources — run with: mix run test/fixtures/dump_golden.exs
{:ok, pe} = LibPE.parse_file("test/fixtures/golden/hello_rcedit.exe")
rsrc = LibPE.get_resources(pe)

alias LibPE.ResourceTable
alias LibPE.ResourceTable.{DirEntry, DataBlob}

dump_type = fn type_name ->
  type_id = LibPE.ResourceTypes.encode(type_name)
  entry = Enum.find(rsrc.entries, fn %DirEntry{name: n} -> n == type_id end)

  if entry == nil do
    IO.puts("#{type_name}: MISSING")
  else
    IO.puts("#{type_name} (#{type_id}):")

    Enum.each(entry.entry.entries, fn %DirEntry{name: name, entry: name_dir} ->
      Enum.each(name_dir.entries, fn %DirEntry{name: lang, entry: %DataBlob{data: data}} ->
        magic = binary_part(data, 0, min(8, byte_size(data))) |> Base.encode16()
        IO.puts("  name=#{inspect(name)} lang=#{lang} size=#{byte_size(data)} head=#{magic}")
      end)
    end)
  end
end

dump_type.("RT_ICON")
dump_type.("RT_GROUP_ICON")

group = ResourceTable.get_resource(rsrc, "RT_GROUP_ICON")

if group do
  data = group.entry.data
  <<res::little-16, type::little-16, count::little-16, rest::binary>> = data
  IO.puts("GRPICONDIR reserved=#{res} type=#{type} count=#{count}")

  Enum.reduce(1..count, rest, fn i, bin ->
    <<w, h, cc, reserved, planes::little-16, bit_count::little-16, bytes::little-32,
      id::little-16, rest::binary>> = bin

    IO.puts(
      "  ##{i} #{w}x#{h} colors=#{cc} planes=#{planes} bpp=#{bit_count} bytes=#{bytes} id=#{id}"
    )

    rest
  end)
end

File.mkdir_p!("test/fixtures/dumps")

icon_entry = Enum.find(rsrc.entries, fn %DirEntry{name: n} -> n == 3 end)
group_entry = Enum.find(rsrc.entries, fn %DirEntry{name: n} -> n == 14 end)

extract = fn %DirEntry{entry: %ResourceTable{entries: names}} ->
  Enum.map(names, fn %DirEntry{name: name, entry: %ResourceTable{entries: langs}} ->
    [%DirEntry{name: lang, entry: %DataBlob{data: data}}] = langs
    %{name: name, lang: lang, data: data}
  end)
end

dump = %{
  icons: if(icon_entry, do: extract.(icon_entry), else: []),
  group: if(group_entry, do: hd(extract.(group_entry)), else: nil),
  checksum: pe.coff_header.checksum,
  checksum_fixed: LibPE.update_checksum(pe).coff_header.checksum
}

File.write!("test/fixtures/dumps/hello_rcedit.term", :erlang.term_to_binary(dump))
IO.puts("Wrote test/fixtures/dumps/hello_rcedit.term")

IO.inspect(%{
  icon_count: length(dump.icons),
  checksum: dump.checksum,
  checksum_fixed: dump.checksum_fixed
})

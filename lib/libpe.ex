defmodule LibPE do
  @moduledoc """
    Implementation of the Windows PE executable format for reading and writing PE binaries.

    Most struct member names are taken directly from the windows documentation:
    https://docs.microsoft.com/en-us/windows/win32/debug/pe-format

    This library has been created specifically to archieve the following:

    * Update the PE checksum in `erl.exe` after making changes
    * Insert a Microsoft manifest file after compilation: https://docs.microsoft.com/de-de/windows/win32/sbscs/application-manifests
    * Insert an Executable Icon after compilation
  """

  @exe_header_size 4
  defstruct [
    :meta,
    :meta2,
    :msdos_stub,
    :format,
    :machine,
    :timestamp,
    :object_offset,
    :object_entry_count,
    :coff_header,
    :coff_flags,
    :coff_sections,
    :rest
  ]

  @spec parse_file(binary()) :: {:ok, %LibPE{}}
  def parse_file(filename) do
    parse_string(File.read!(filename))
  end

  @spec parse_string(binary()) :: {:ok, %LibPE{}}
  def parse_string(
        <<"MZ", meta::binary-size(6), @exe_header_size::little-size(16), meta2::binary-size(50),
          offset::little-size(32), rest::binary>> = full_image
      ) do
    # exe header is always 64 bytes
    stub_size = offset - @exe_header_size * 16

    <<msdos_stub::binary-size(stub_size), coff::binary>> = rest

    pe =
      %LibPE{meta: meta, meta2: meta2, msdos_stub: msdos_stub, rest: ""}
      |> parse_coff(coff, full_image)

    end_offset = byte_size(encode(pe))

    pe =
      if end_offset < byte_size(full_image) do
        %LibPE{pe | rest: binary_part(full_image, end_offset, byte_size(full_image) - end_offset)}
      else
        pe
      end

    {:ok, pe}
  end

  @spec encode(%LibPE{}) :: binary()
  def encode(%LibPE{rest: rest, coff_sections: sections, coff_header: header} = pe) do
    image = encode_header(pe)

    # Compare with Section.parse_section()
    # We assume the `raw_data` is the actual "virtual" payload
    # So we fit it here (padding or cutting) into the raw size because
    # often the real payload is smaller than the file space, but sometimes it can
    # be larger as well (when the tail is only made of zeros)
    image =
      Enum.reduce(sections, image, fn sec, image ->
        binary_pad_trailing(image, sec.pointer_to_raw_data) <> sec.raw_data
      end)

    image =
      if header.certificate_data != nil do
        {start, _size} = header.certificate_table
        binary_pad_trailing(image, start) <> header.certificate_data
      else
        image
      end

    image <> rest
  end

  defp encode_header(%LibPE{meta: meta, meta2: meta2, msdos_stub: msdos_stub} = pe) do
    stub_size = byte_size(msdos_stub)
    offset = stub_size + @exe_header_size * 16

    coff = encode_coff(pe)

    <<"MZ", meta::binary-size(6), @exe_header_size::little-size(16), meta2::binary-size(50),
      offset::little-size(32), msdos_stub::binary-size(stub_size), coff::binary>>
  end

  defp parse_coff(pe, <<"PE\0\0", rest::binary>>, full_image) do
    parse_coff(%LibPE{pe | format: :pe}, rest, full_image)
  end

  defp parse_coff(
         %LibPE{} = pe,
         <<machine::little-size(16), number_of_sections::little-size(16),
           timestamp::little-size(32), object_offset::little-size(32),
           object_entry_count::little-size(32), coff_header_size::little-size(16),
           coff_flags::little-size(16), rest::binary>>,
         full_image
       ) do
    <<header::binary-size(coff_header_size), rest::binary>> = rest
    header = LibPE.OptionalHeader.parse(header, full_image)
    {sections, _rest} = LibPE.Section.parse(rest, number_of_sections, full_image)

    %LibPE{
      pe
      | machine: LibPE.MachineType.decode(machine),
        timestamp: timestamp,
        object_offset: object_offset,
        object_entry_count: object_entry_count,
        coff_header: header,
        coff_flags: LibPE.Characteristics.decode(coff_flags),
        coff_sections: sections
    }
  end

  defp encode_coff(%LibPE{format: :pe} = pe) do
    "PE\0\0" <> encode_coff(%LibPE{pe | format: nil})
  end

  defp encode_coff(%LibPE{
         machine: machine,
         timestamp: timestamp,
         object_offset: object_offset,
         object_entry_count: object_entry_count,
         coff_header: header,
         coff_flags: coff_flags,
         coff_sections: sections
       }) do
    machine = LibPE.MachineType.encode(machine)
    coff_flags = LibPE.Characteristics.encode(coff_flags)
    header = LibPE.OptionalHeader.encode(header)
    coff_header_size = byte_size(header)

    number_of_sections = length(sections)

    sections = Enum.map_join(sections, &LibPE.Section.encode/1)

    <<machine::little-size(16), number_of_sections::little-size(16), timestamp::little-size(32),
      object_offset::little-size(32), object_entry_count::little-size(32),
      coff_header_size::little-size(16), coff_flags::little-size(16), header::binary,
      sections::binary>>
  end

  @doc """
    Update the PE image checksum of a PE file.
  """
  def update_checksum(%LibPE{} = pe) do
    tmp_pe =
      %LibPE{pe | coff_header: %LibPE.OptionalHeader{pe.coff_header | checksum: 0}}
      |> encode()

    # size = byte_size(tmp_pe) + byte_size(LibPE.OptionalHeader.encode_checksum(pe.coff_header))
    size = byte_size(tmp_pe)

    # correcting size for the missing checksum field
    new_checksum = LibPE.Checksum.checksum(tmp_pe, size)
    %LibPE{pe | coff_header: %LibPE.OptionalHeader{pe.coff_header | checksum: new_checksum}}
  end

  @doc """
    Update the section & certificate layout after a section size has
    been changed
  """
  @quad_word_size 64
  def update_layout(%LibPE{coff_sections: sections, coff_header: header} = pe) do
    offset = byte_size(encode_header(pe))

    %LibPE.OptionalHeader{file_alignment: file_alignment, section_alignment: virtual_alignment} =
      header

    {sections, offsets} =
      Enum.map_reduce(sections, {offset, offset}, fn %LibPE.Section{
                                                       virtual_data: virtual_data
                                                     } = sec,
                                                     {virtual, raw} ->
        virtual = ceil(virtual / virtual_alignment) * virtual_alignment
        raw = ceil(raw / file_alignment) * file_alignment

        virtual_size = byte_size(virtual_data)
        raw_size = byte_size(String.trim_trailing(virtual_data, "\0"))
        raw_size = ceil(raw_size / file_alignment) * file_alignment

        raw_data =
          if virtual_size < raw_size do
            binary_pad_trailing(virtual_data, raw_size, sec.padding)
          else
            binary_part(virtual_data, 0, raw_size)
          end

        sec = %LibPE.Section{
          sec
          | pointer_to_raw_data: raw,
            size_of_raw_data: raw_size,
            virtual_address: virtual,
            virtual_size: virtual_size,
            raw_data: raw_data
        }

        {sec, {virtual + virtual_size, raw + raw_size}}
      end)

    header =
      if header.certificate_data != nil do
        {_virtual, raw} = offsets
        start = ceil(raw / @quad_word_size) * @quad_word_size

        %LibPE.OptionalHeader{
          header
          | certificate_table: {start, byte_size(header.certificate_data)}
        }
      else
        %LibPE.OptionalHeader{header | certificate_table: {0, 0}}
      end

    # Only updating the physical tables `.rsrc` and `.reloc`
    header =
      [
        # export_table: ".edata",
        # import_table: ".idata",
        resource_table: ".rsrc",
        # exception_table: ".pdata",
        base_relocation_table: ".reloc"
        # debug: ".debug",
        # tls_table: ".tls"
      ]
      |> Enum.reduce(header, fn {field_name, section_name}, header ->
        case Enum.find(sections, fn %LibPE.Section{name: name} -> name == section_name end) do
          nil ->
            Map.put(header, field_name, {0, 0})

          %LibPE.Section{virtual_address: virtual_address, virtual_size: virtual_size} ->
            Map.put(header, field_name, {virtual_address, virtual_size})
        end
      end)

    header =
      case List.last(sections) do
        %LibPE.Section{virtual_address: addr, virtual_size: size} ->
          %LibPE.OptionalHeader{
            header
            | size_of_image: ceil((addr + size) / virtual_alignment) * virtual_alignment
          }

        nil ->
          header
      end

    %LibPE{pe | coff_sections: sections, coff_header: header}
  end

  def get_resources(%LibPE{coff_sections: sections}) do
    case Enum.find(sections, fn %LibPE.Section{name: name} -> name == ".rsrc" end) do
      %LibPE.Section{virtual_data: virtual_data, virtual_address: virtual_address} ->
        LibPE.ResourceTable.parse(virtual_data, virtual_address)

      nil ->
        nil
    end
  end

  def set_resources(%LibPE{coff_sections: sections} = pe, resources = %LibPE.ResourceTable{}) do
    # need to ensure that the virtual_address is up-to-date
    pe = update_layout(pe)

    # now fetching and setting the resource
    idx = Enum.find_index(sections, fn %LibPE.Section{name: name} -> name == ".rsrc" end)

    section = %LibPE.Section{virtual_address: virtual_address} = Enum.at(sections, idx)
    data = LibPE.ResourceTable.encode(resources, virtual_address)
    section = %LibPE.Section{section | virtual_data: data}

    sections = List.update_at(sections, idx, fn _ -> section end)

    # updating offsets coming after the ".rsrc" section
    %LibPE{pe | coff_sections: sections}
    |> update_layout()
  end

  def set_resource(
        pe,
        resource_type,
        data,
        codepage \\ 0,
        language \\ 1033
      ) do
    resources =
      get_resources(pe)
      |> LibPE.ResourceTable.set_resource(resource_type, data, codepage, language)

    set_resources(pe, resources)
  end

  @doc false
  def binary_pad_trailing(binary, size, padding \\ <<0>>)

  def binary_pad_trailing(binary, size, padding) when byte_size(binary) < size do
    bytesize = size - byte_size(binary)
    padding = String.duplicate(padding, ceil(bytesize / byte_size(padding)) * byte_size(padding))
    binary <> binary_part(padding, 0, bytesize)
  end

  def binary_pad_trailing(binary, _size, _padding) do
    binary
  end

  @doc false
  def binary_extract(binary, start, size) do
    content = binary_part(binary, start, size)

    binary =
      binary_part(binary, 0, start) <>
        binary_pad_trailing("", size) <>
        binary_part(binary, start + size, byte_size(binary) - (start + size))

    {binary, content}
  end
end

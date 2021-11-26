defmodule LibPE do
  @moduledoc """
  Documentation for `LibPE`.
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

  def parse_file(filename) do
    parse_string(File.read!(filename))
  end

  # https://www.lowlevel.eu/wiki/Microsoft_Portable_Executable_and_Common_Object_File_Format
  # https://docs.microsoft.com/en-us/windows/win32/debug/pe-format
  def parse_string(
        <<"MZ", meta::binary-size(6), @exe_header_size::little-size(16), meta2::binary-size(50),
          offset::little-size(32), rest::binary>> = full_image
      ) do
    # exe header is always 64 bytes
    stub_size = offset - @exe_header_size * 16

    <<msdos_stub::binary-size(stub_size), coff::binary>> = rest

    pe =
      %LibPE{meta: meta, meta2: meta2, msdos_stub: msdos_stub}
      |> parse_coff(coff, full_image)

    {:ok, pe}
  end

  def encode(%LibPE{} = pe) do
    header = encode_header(pe)

    # Compare with Section.parse_section()
    # We assume the `raw_data` is the actual "virtual" payload
    # So we fit it here (padding or cutting) into the raw size because
    # often the real payload is smaller than the file space, but sometimes it can
    # be larger as well (when the tail is only made of zeros)
    image =
      Enum.reduce(pe.coff_sections, header, fn sec, image ->
        binary_pad_trailing(image, sec.pointer_to_raw_data) <> sec.raw_data
      end)

    image =
      if pe.coff_header.certificate_data != nil do
        {start, _size} = pe.coff_header.certificate_table
        binary_pad_trailing(image, start) <> pe.coff_header.certificate_data
      else
        image
      end

    image
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
         pe = %LibPE{},
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

    sections =
      Enum.map(sections, &LibPE.Section.encode/1)
      |> Enum.join()

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
  def update_layout(%LibPE{} = pe) do
    header_offset = byte_size(encode_header(pe))
    header = pe.coff_header
    file_alignment = header.file_alignment
    virtual_alignment = header.section_alignment

    {sections, offsets} =
      Enum.map_reduce(pe.coff_sections, {header_offset, header_offset}, fn %LibPE.Section{} = sec,
                                                                           {virtual, raw} ->
        virtual = ceil(virtual / virtual_alignment) * virtual_alignment
        raw = ceil(raw / file_alignment) * file_alignment

        virtual_size = byte_size(sec.virtual_data)
        raw_size = byte_size(String.trim_trailing(sec.virtual_data, "\0"))
        raw_size = ceil(raw_size / file_alignment) * file_alignment

        raw_data =
          if virtual_size < raw_size do
            binary_pad_trailing(sec.virtual_data, raw_size, sec.padding)
          else
            binary_part(sec.virtual_data, 0, raw_size)
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

    %LibPE{pe | coff_sections: sections, coff_header: header}
  end

  @doc false
  def binary_pad_trailing(binary, size, padding \\ <<0>>)

  def binary_pad_trailing(binary, size, padding) when byte_size(binary) < size do
    bytesize = size - byte_size(binary)
    padding = String.duplicate(padding, ceil(bytesize / byte_size(padding)) * bytesize)
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

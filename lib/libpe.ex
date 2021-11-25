defmodule LibPE do
  @moduledoc """
  Documentation for `LibPE`.
  """

  @exe_header_size 4
  defstruct [
    # Original raw image to lookup offset based data
    :full_image,
    :meta,
    :meta2,
    :msdos_stub,
    :format,
    :machine,
    :number_of_sections,
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
          offset::little-size(32), rest::binary>> = full
      ) do
    # exe header is always 64 bytes
    stub_size = offset - @exe_header_size * 16

    <<msdos_stub::binary-size(stub_size), coff::binary>> = rest

    pe =
      %LibPE{full_image: full, meta: meta, meta2: meta2, msdos_stub: msdos_stub}
      |> parse_coff(coff)

    {:ok, pe}
  end

  def encode(%LibPE{meta: meta, meta2: meta2, msdos_stub: msdos_stub} = pe) do
    stub_size = byte_size(msdos_stub)
    offset = stub_size + @exe_header_size * 16

    coff = encode_coff(pe)
    rest = <<msdos_stub::binary-size(stub_size), coff::binary>>

    <<"MZ", meta::binary-size(6), @exe_header_size::little-size(16), meta2::binary-size(50),
      offset::little-size(32), rest::binary>>
  end

  def parse_coff(pe, <<"PE\0\0", rest::binary>>) do
    parse_coff(%LibPE{pe | format: :pe}, rest)
  end

  def parse_coff(
        pe,
        <<machine::little-size(16), number_of_sections::little-size(16),
          timestamp::little-size(32), object_offset::little-size(32),
          object_entry_count::little-size(32), coff_header_size::little-size(16),
          coff_flags::little-size(16), rest::binary>>
      ) do
    <<header::binary-size(coff_header_size), rest::binary>> = rest
    header = LibPE.OptionalHeader.parse(header)
    {sections, rest} = parse_sections(rest, number_of_sections)

    %LibPE{
      pe
      | machine: LibPE.MachineType.decode(machine),
        number_of_sections: number_of_sections,
        timestamp: timestamp,
        object_offset: object_offset,
        object_entry_count: object_entry_count,
        coff_header: header,
        coff_flags: LibPE.Characteristics.decode(coff_flags),
        coff_sections: sections,
        rest: rest
    }
  end

  def encode_coff(%LibPE{format: :pe} = pe) do
    "PE\0\0" <> encode_coff(%LibPE{pe | format: nil})
  end

  def encode_coff(%LibPE{
        machine: machine,
        number_of_sections: number_of_sections,
        timestamp: timestamp,
        object_offset: object_offset,
        object_entry_count: object_entry_count,
        coff_header: header,
        coff_flags: coff_flags,
        coff_sections: sections,
        rest: rest
      }) do
    machine = LibPE.MachineType.encode(machine)
    coff_flags = LibPE.Characteristics.encode(coff_flags)
    header = LibPE.OptionalHeader.encode(header)
    coff_header_size = byte_size(header)

    sections =
      Enum.map(sections, &encode_section/1)
      |> Enum.join()

    <<machine::little-size(16), number_of_sections::little-size(16), timestamp::little-size(32),
      object_offset::little-size(32), object_entry_count::little-size(32),
      coff_header_size::little-size(16), coff_flags::little-size(16), header::binary,
      sections::binary, rest::binary>>
  end

  defmodule Section do
    defstruct [
      :name,
      :virtual_size,
      :virtual_address,
      :size_of_raw_data,
      :pointer_to_raw_data,
      :pointer_to_relocations,
      :pointer_to_linenumbers,
      :number_of_relocations,
      :number_of_linenumbers,
      :flags
    ]
  end

  def parse_sections(rest, number) do
    List.duplicate(nil, number)
    |> Enum.reduce({[], rest}, fn _, {sections, rest} ->
      {section, rest} = parse_section(rest)
      {sections ++ [section], rest}
    end)
  end

  def parse_section(
        <<name::binary-size(8), virtual_size::little-size(32), virtual_address::little-size(32),
          size_of_raw_data::little-size(32), pointer_to_raw_data::little-size(32),
          pointer_to_relocations::little-size(32), pointer_to_linenumbers::little-size(32),
          number_of_relocations::little-size(16), number_of_linenumbers::little-size(16),
          flags::little-size(32), rest::binary()>>
      ) do
    section = %Section{
      name: name,
      virtual_size: virtual_size,
      virtual_address: virtual_address,
      size_of_raw_data: size_of_raw_data,
      pointer_to_raw_data: pointer_to_raw_data,
      pointer_to_relocations: pointer_to_relocations,
      pointer_to_linenumbers: pointer_to_linenumbers,
      number_of_relocations: number_of_relocations,
      number_of_linenumbers: number_of_linenumbers,
      flags: LibPE.SectionFlags.decode(flags)
    }

    {section, rest}
  end

  def encode_section(%Section{
        name: name,
        virtual_size: virtual_size,
        virtual_address: virtual_address,
        size_of_raw_data: size_of_raw_data,
        pointer_to_raw_data: pointer_to_raw_data,
        pointer_to_relocations: pointer_to_relocations,
        pointer_to_linenumbers: pointer_to_linenumbers,
        number_of_relocations: number_of_relocations,
        number_of_linenumbers: number_of_linenumbers,
        flags: flags
      }) do
    flags = LibPE.SectionFlags.encode(flags)

    <<name::binary-size(8), virtual_size::little-size(32), virtual_address::little-size(32),
      size_of_raw_data::little-size(32), pointer_to_raw_data::little-size(32),
      pointer_to_relocations::little-size(32), pointer_to_linenumbers::little-size(32),
      number_of_relocations::little-size(16), number_of_linenumbers::little-size(16),
      flags::little-size(32)>>
  end

  def generate_image() do
  end
end

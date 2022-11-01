defmodule LibPE.Section do
  @moduledoc false
  alias LibPE.Section

  defstruct [
    :name,
    :padding,
    :virtual_data,
    :virtual_size,
    :virtual_address,
    :raw_data,
    :size_of_raw_data,
    :pointer_to_raw_data,
    :pointer_to_relocations,
    :pointer_to_linenumbers,
    :number_of_relocations,
    :number_of_linenumbers,
    :flags
  ]

  def parse(rest, number, full_image) do
    List.duplicate(nil, number)
    |> Enum.reduce({[], rest}, fn _, {sections, rest} ->
      {section, rest} = parse_section(rest, full_image)
      {sections ++ [section], rest}
    end)
  end

  defp parse_section(
         <<name::binary-size(8), virtual_size::little-size(32), virtual_address::little-size(32),
           size_of_raw_data::little-size(32), pointer_to_raw_data::little-size(32),
           pointer_to_relocations::little-size(32), pointer_to_linenumbers::little-size(32),
           number_of_relocations::little-size(16), number_of_linenumbers::little-size(16),
           flags::little-size(32), rest::binary>>,
         full_image
       ) do
    raw_data = binary_part(full_image, pointer_to_raw_data, size_of_raw_data)

    # According to spec there should only be a zero padding difference between raw_data
    # and virtual data... BUT in production we can see that Microsoft is using other paddings
    # such as 'PADDINGXX' in some cases :-(
    virtual_data =
      binary_part(full_image, pointer_to_raw_data, min(size_of_raw_data, virtual_size))
      |> LibPE.binary_pad_trailing(virtual_size)

    padding =
      if virtual_size >= size_of_raw_data do
        "\0"
      else
        binary_part(raw_data, virtual_size, min(16, size_of_raw_data - virtual_size))
      end

    section = %Section{
      name: String.trim_trailing(name, "\0"),
      padding: padding,
      virtual_size: virtual_size,
      virtual_address: virtual_address,
      raw_data: raw_data,
      virtual_data: virtual_data,
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

  def encode(%Section{
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

    name = LibPE.binary_pad_trailing(name, 8)

    <<name::binary-size(8), virtual_size::little-size(32), virtual_address::little-size(32),
      size_of_raw_data::little-size(32), pointer_to_raw_data::little-size(32),
      pointer_to_relocations::little-size(32), pointer_to_linenumbers::little-size(32),
      number_of_relocations::little-size(16), number_of_linenumbers::little-size(16),
      flags::little-size(32)>>
  end
end

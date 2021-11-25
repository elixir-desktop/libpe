defmodule LibPE.OptionalHeader do
  alias LibPE.OptionalHeader

  defstruct [
    :magic,
    :major_linker_version,
    :minor_linker_version,
    :size_of_code,
    :size_of_initialized_data,
    :size_of_uninitialized_data,
    :address_of_entrypoint,
    :base_of_code,
    # only for PE
    :base_of_data,

    # windows extra headers
    :image_base,
    :section_alignment,
    :file_alignment,
    :major_operating_system,
    :minor_operating_system,
    :major_image_version,
    :minor_image_version,
    :major_subsystem_version,
    :minor_subsystem_version,
    :win32_version_value,
    :size_of_image,
    :size_of_headers,
    :checksum,
    :subsystem,
    :dll_characteristics,
    :size_of_stack_reserve,
    :size_of_stack_commit,
    :size_of_heap_reserve,
    :size_of_heap_commit,
    :loader_flags,
    :number_of_rva_and_sizes,

    # data directories
    :export_table,
    :import_table,
    :resource_table,
    :exception_table,
    :certificate_table,
    :base_relocation_table,
    :debug,
    :architecture,
    :global_ptr,
    :tls_table,
    :load_config_table,
    :bound_import,
    :iat,
    :delay_import_descriptor,
    :clr_runtime_header,
    :reserved
  ]

  @magic_pe 0x10B
  @magic_rom 0x107
  @magic_pe_plus 0x20B
  def parse("") do
    nil
  end

  def parse(
        <<magic::little-size(16), major_linker_version::little-size(8),
          minor_linker_version::little-size(8), size_of_code::little-size(32),
          size_of_initialized_data::little-size(32), size_of_uninitialized_data::little-size(32),
          address_of_entrypoint::little-size(32), base_of_code::little-size(32), rest::binary>>
      ) do
    header = %OptionalHeader{
      magic: magic,
      major_linker_version: major_linker_version,
      minor_linker_version: minor_linker_version,
      size_of_code: size_of_code,
      size_of_initialized_data: size_of_initialized_data,
      size_of_uninitialized_data: size_of_uninitialized_data,
      address_of_entrypoint: address_of_entrypoint,
      base_of_code: base_of_code
    }

    {header, rest} =
      case magic do
        @magic_pe ->
          <<base_of_data::little-size(32), rest::binary>> = rest
          {%OptionalHeader{header | base_of_data: base_of_data}, rest}

        # This is not documented so we just treat it the same as a PE
        @magic_rom ->
          <<base_of_data::little-size(32), rest::binary>> = rest
          {%OptionalHeader{header | base_of_data: base_of_data}, rest}

        @magic_pe_plus ->
          {header, rest}
      end

    {header, rest} = parse_windows_extra(magic, rest, header)
    parse_data_directories(rest, header)
  end

  def encode(
        %OptionalHeader{
          magic: magic,
          major_linker_version: major_linker_version,
          minor_linker_version: minor_linker_version,
          size_of_code: size_of_code,
          size_of_initialized_data: size_of_initialized_data,
          size_of_uninitialized_data: size_of_uninitialized_data,
          address_of_entrypoint: address_of_entrypoint,
          base_of_code: base_of_code,
          base_of_data: base_of_data
        } = header
      ) do
    <<magic::little-size(16), major_linker_version::little-size(8),
      minor_linker_version::little-size(8), size_of_code::little-size(32),
      size_of_initialized_data::little-size(32), size_of_uninitialized_data::little-size(32),
      address_of_entrypoint::little-size(32),
      base_of_code::little-size(32)>> <>
      case magic do
        @magic_pe -> <<base_of_data::little-size(32)>>
        @magic_rom -> <<base_of_data::little-size(32)>>
        @magic_pe_plus -> <<>>
      end <>
      encode_windows_extra(header) <>
      encode_data_directories(header)
  end

  def parse_windows_extra(
        @magic_pe,
        <<image_base::little-size(32), section_alignment::little-size(32),
          file_alignment::little-size(32), major_operating_system::little-size(16),
          minor_operating_system::little-size(16), major_image_version::little-size(16),
          minor_image_version::little-size(16), major_subsystem_version::little-size(16),
          minor_subsystem_version::little-size(16), win32_version_value::little-size(32),
          size_of_image::little-size(32), size_of_headers::little-size(32),
          checksum::little-size(32), subsystem::little-size(16),
          dll_characteristics::little-size(16), size_of_stack_reserve::little-size(32),
          size_of_stack_commit::little-size(32), size_of_heap_reserve::little-size(32),
          size_of_heap_commit::little-size(32), loader_flags::little-size(32),
          number_of_rva_and_sizes::little-size(32), rest::binary>>,
        header
      ) do
    {%OptionalHeader{
       header
       | image_base: image_base,
         section_alignment: section_alignment,
         file_alignment: file_alignment,
         major_operating_system: major_operating_system,
         minor_operating_system: minor_operating_system,
         major_image_version: major_image_version,
         minor_image_version: minor_image_version,
         major_subsystem_version: major_subsystem_version,
         minor_subsystem_version: minor_subsystem_version,
         win32_version_value: win32_version_value,
         size_of_image: size_of_image,
         size_of_headers: size_of_headers,
         checksum: checksum,
         subsystem: LibPE.WindowsSubsystem.decode(subsystem),
         dll_characteristics: LibPE.DLLCharacteristics.decode(dll_characteristics),
         size_of_stack_reserve: size_of_stack_reserve,
         size_of_stack_commit: size_of_stack_commit,
         size_of_heap_reserve: size_of_heap_reserve,
         size_of_heap_commit: size_of_heap_commit,
         loader_flags: loader_flags,
         number_of_rva_and_sizes: number_of_rva_and_sizes
     }, rest}
  end

  def parse_windows_extra(
        @magic_pe_plus,
        <<image_base::little-size(64), section_alignment::little-size(32),
          file_alignment::little-size(32), major_operating_system::little-size(16),
          minor_operating_system::little-size(16), major_image_version::little-size(16),
          minor_image_version::little-size(16), major_subsystem_version::little-size(16),
          minor_subsystem_version::little-size(16), win32_version_value::little-size(32),
          size_of_image::little-size(32), size_of_headers::little-size(32),
          checksum::little-size(32), subsystem::little-size(16),
          dll_characteristics::little-size(16), size_of_stack_reserve::little-size(64),
          size_of_stack_commit::little-size(64), size_of_heap_reserve::little-size(64),
          size_of_heap_commit::little-size(64), loader_flags::little-size(32),
          number_of_rva_and_sizes::little-size(32), rest::binary>>,
        header
      ) do
    {%OptionalHeader{
       header
       | image_base: image_base,
         section_alignment: section_alignment,
         file_alignment: file_alignment,
         major_operating_system: major_operating_system,
         minor_operating_system: minor_operating_system,
         major_image_version: major_image_version,
         minor_image_version: minor_image_version,
         major_subsystem_version: major_subsystem_version,
         minor_subsystem_version: minor_subsystem_version,
         win32_version_value: win32_version_value,
         size_of_image: size_of_image,
         size_of_headers: size_of_headers,
         checksum: checksum,
         subsystem: LibPE.WindowsSubsystem.decode(subsystem),
         dll_characteristics: LibPE.DLLCharacteristics.decode(dll_characteristics),
         size_of_stack_reserve: size_of_stack_reserve,
         size_of_stack_commit: size_of_stack_commit,
         size_of_heap_reserve: size_of_heap_reserve,
         size_of_heap_commit: size_of_heap_commit,
         loader_flags: loader_flags,
         number_of_rva_and_sizes: number_of_rva_and_sizes
     }, rest}
  end

  def encode_windows_extra(%OptionalHeader{
        magic: magic,
        image_base: image_base,
        section_alignment: section_alignment,
        file_alignment: file_alignment,
        major_operating_system: major_operating_system,
        minor_operating_system: minor_operating_system,
        major_image_version: major_image_version,
        minor_image_version: minor_image_version,
        major_subsystem_version: major_subsystem_version,
        minor_subsystem_version: minor_subsystem_version,
        win32_version_value: win32_version_value,
        size_of_image: size_of_image,
        size_of_headers: size_of_headers,
        checksum: checksum,
        subsystem: subsystem,
        dll_characteristics: dll_characteristics,
        size_of_stack_reserve: size_of_stack_reserve,
        size_of_stack_commit: size_of_stack_commit,
        size_of_heap_reserve: size_of_heap_reserve,
        size_of_heap_commit: size_of_heap_commit,
        loader_flags: loader_flags,
        number_of_rva_and_sizes: number_of_rva_and_sizes
      }) do
    subsystem = LibPE.WindowsSubsystem.encode(subsystem)
    dll_characteristics = LibPE.DLLCharacteristics.encode(dll_characteristics)

    # this allows creating a new checksum
    case magic do
      @magic_pe ->
        <<image_base::little-size(32), section_alignment::little-size(32),
          file_alignment::little-size(32), major_operating_system::little-size(16),
          minor_operating_system::little-size(16), major_image_version::little-size(16),
          minor_image_version::little-size(16), major_subsystem_version::little-size(16),
          minor_subsystem_version::little-size(16), win32_version_value::little-size(32),
          size_of_image::little-size(32), size_of_headers::little-size(32),
          checksum::little-size(32), subsystem::little-size(16),
          dll_characteristics::little-size(16), size_of_stack_reserve::little-size(32),
          size_of_stack_commit::little-size(32), size_of_heap_reserve::little-size(32),
          size_of_heap_commit::little-size(32), loader_flags::little-size(32),
          number_of_rva_and_sizes::little-size(32)>>

      @magic_pe_plus ->
        <<image_base::little-size(64), section_alignment::little-size(32),
          file_alignment::little-size(32), major_operating_system::little-size(16),
          minor_operating_system::little-size(16), major_image_version::little-size(16),
          minor_image_version::little-size(16), major_subsystem_version::little-size(16),
          minor_subsystem_version::little-size(16), win32_version_value::little-size(32),
          size_of_image::little-size(32), size_of_headers::little-size(32),
          checksum::little-size(32), subsystem::little-size(16),
          dll_characteristics::little-size(16), size_of_stack_reserve::little-size(64),
          size_of_stack_commit::little-size(64), size_of_heap_reserve::little-size(64),
          size_of_heap_commit::little-size(64), loader_flags::little-size(32),
          number_of_rva_and_sizes::little-size(32)>>
    end
  end

  def parse_data_directories(
        <<export_table::little-size(64), import_table::little-size(64),
          resource_table::little-size(64), exception_table::little-size(64),
          certificate_table::little-size(64), base_relocation_table::little-size(64),
          debug::little-size(64), architecture::little-size(64), global_ptr::little-size(64),
          tls_table::little-size(64), load_config_table::little-size(64),
          bound_import::little-size(64), iat::little-size(64),
          delay_import_descriptor::little-size(64), clr_runtime_header::little-size(64),
          reserved::little-size(64)>>,
        pe
      ) do
    %OptionalHeader{
      pe
      | export_table: export_table,
        import_table: import_table,
        resource_table: resource_table,
        exception_table: exception_table,
        certificate_table: certificate_table,
        base_relocation_table: base_relocation_table,
        debug: debug,
        architecture: architecture,
        global_ptr: global_ptr,
        tls_table: tls_table,
        load_config_table: load_config_table,
        bound_import: bound_import,
        iat: iat,
        delay_import_descriptor: delay_import_descriptor,
        clr_runtime_header: clr_runtime_header,
        reserved: reserved
    }
  end

  def encode_data_directories(%OptionalHeader{
        export_table: export_table,
        import_table: import_table,
        resource_table: resource_table,
        exception_table: exception_table,
        certificate_table: certificate_table,
        base_relocation_table: base_relocation_table,
        debug: debug,
        architecture: architecture,
        global_ptr: global_ptr,
        tls_table: tls_table,
        load_config_table: load_config_table,
        bound_import: bound_import,
        iat: iat,
        delay_import_descriptor: delay_import_descriptor,
        clr_runtime_header: clr_runtime_header,
        reserved: reserved
      }) do
    <<export_table::little-size(64), import_table::little-size(64),
      resource_table::little-size(64), exception_table::little-size(64),
      certificate_table::little-size(64), base_relocation_table::little-size(64),
      debug::little-size(64), architecture::little-size(64), global_ptr::little-size(64),
      tls_table::little-size(64), load_config_table::little-size(64),
      bound_import::little-size(64), iat::little-size(64),
      delay_import_descriptor::little-size(64), clr_runtime_header::little-size(64),
      reserved::little-size(64)>>
  end
end

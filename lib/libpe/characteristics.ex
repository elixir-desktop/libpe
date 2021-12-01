defmodule LibPE.Characteristics do
  use LibPE.Flags, [:many]

  def flags() do
    [
      {"IMAGE_FILE_RELOCS_STRIPPED", 0x0001,
       "Image only, Windows CE, and Microsoft Windows NT and later. This indicates that the file does not contain base relocations and must therefore be loaded at its preferred base address. If the base address is not available, the loader reports an error. The default behavior of the linker is to strip base relocations from executable (EXE) files."},
      {"IMAGE_FILE_EXECUTABLE_IMAGE", 0x0002,
       "Image only. This indicates that the image file is valid and can be run. If this flag is not set, it indicates a linker error."},
      {"IMAGE_FILE_LINE_NUMS_STRIPPED", 0x0004,
       "COFF line numbers have been removed. This flag is deprecated and should be zero."},
      {"IMAGE_FILE_LOCAL_SYMS_STRIPPED", 0x0008,
       "COFF symbol table entries for local symbols have been removed. This flag is deprecated and should be zero."},
      {"IMAGE_FILE_AGGRESSIVE_WS_TRIM", 0x0010,
       "Obsolete. Aggressively trim working set. This flag is deprecated for Windows 2000 and later and must be zero."},
      {"IMAGE_FILE_LARGE_ADDRESS_ AWARE", 0x0020, "Application can handle > 2-GB addresses."},
      {"", 0x0040, "This flag is reserved for future use."},
      {"IMAGE_FILE_BYTES_REVERSED_LO", 0x0080,
       "Little endian: the least significant bit (LSB) precedes the most significant bit (MSB) in memory. This flag is deprecated and should be zero."},
      {"IMAGE_FILE_32BIT_MACHINE", 0x0100, "Machine is based on a 32-bit-word architecture."},
      {"IMAGE_FILE_DEBUG_STRIPPED", 0x0200,
       "Debugging information is removed from the image file."},
      {"IMAGE_FILE_REMOVABLE_RUN_ FROM_SWAP", 0x0400,
       "If the image is on removable media, fully load it and copy it to the swap file."},
      {"IMAGE_FILE_NET_RUN_FROM_SWAP", 0x0800,
       "If the image is on network media, fully load it and copy it to the swap file."},
      {"IMAGE_FILE_SYSTEM", 0x1000, "The image file is a system file, not a user program."},
      {"IMAGE_FILE_DLL", 0x2000,
       "The image file is a dynamic-link library (DLL). Such files are considered executable files for almost all purposes, although they cannot be directly run."},
      {"IMAGE_FILE_UP_SYSTEM_ONLY", 0x4000,
       "The file should be run only on a uniprocessor machine."},
      {"IMAGE_FILE_BYTES_REVERSED_HI", 0x8000,
       "Big endian: the MSB precedes the LSB in memory. This flag is deprecated and should be zero.     ]"}
    ]
  end
end

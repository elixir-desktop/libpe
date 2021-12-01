defmodule LibPE.MachineType do
  use LibPE.Flags

  def flags() do
    [
      {"IMAGE_FILE_MACHINE_UNKNOWN", 0x0,
       "The content of this field is assumed to be applicable to any machine type"},
      {"IMAGE_FILE_MACHINE_AM33", 0x1D3, "Matsushita AM33"},
      {"IMAGE_FILE_MACHINE_AMD64", 0x8664, "x64"},
      {"IMAGE_FILE_MACHINE_ARM", 0x1C0, "ARM little endian"},
      {"IMAGE_FILE_MACHINE_ARM64", 0xAA64, "ARM64 little endian"},
      {"IMAGE_FILE_MACHINE_ARMNT", 0x1C4, "ARM Thumb-2 little endian"},
      {"IMAGE_FILE_MACHINE_EBC", 0xEBC, "EFI byte code"},
      {"IMAGE_FILE_MACHINE_I386", 0x14C,
       "Intel 386 or later processors and compatible processors"},
      {"IMAGE_FILE_MACHINE_IA64", 0x200, "Intel Itanium processor family"},
      {"IMAGE_FILE_MACHINE_LOONGARCH32", 0x6232, "LoongArch 32-bit processor family"},
      {"IMAGE_FILE_MACHINE_LOONGARCH64", 0x6264, "LoongArch 64-bit processor family"},
      {"IMAGE_FILE_MACHINE_M32R", 0x9041, "Mitsubishi M32R little endian"},
      {"IMAGE_FILE_MACHINE_MIPS16", 0x266, "MIPS16"},
      {"IMAGE_FILE_MACHINE_MIPSFPU", 0x366, "MIPS with FPU"},
      {"IMAGE_FILE_MACHINE_MIPSFPU16", 0x466, "MIPS16 with FPU"},
      {"IMAGE_FILE_MACHINE_POWERPC", 0x1F0, "Power PC little endian"},
      {"IMAGE_FILE_MACHINE_POWERPCFP", 0x1F1, "Power PC with floating point support"},
      {"IMAGE_FILE_MACHINE_R4000", 0x166, "MIPS little endian"},
      {"IMAGE_FILE_MACHINE_RISCV32", 0x5032, "RISC-V 32-bit address space"},
      {"IMAGE_FILE_MACHINE_RISCV64", 0x5064, "RISC-V 64-bit address space"},
      {"IMAGE_FILE_MACHINE_RISCV128", 0x5128, "RISC-V 128-bit address space"},
      {"IMAGE_FILE_MACHINE_SH3", 0x1A2, "Hitachi SH3"},
      {"IMAGE_FILE_MACHINE_SH3DSP", 0x1A3, "Hitachi SH3 DSP"},
      {"IMAGE_FILE_MACHINE_SH4", 0x1A6, "Hitachi SH4"},
      {"IMAGE_FILE_MACHINE_SH5", 0x1A8, "Hitachi SH5"},
      {"IMAGE_FILE_MACHINE_THUMB", 0x1C2, "Thumb"},
      {"IMAGE_FILE_MACHINE_WCEMIPSV2", 0x169, "MIPS little-endian WCE v2"}
    ]
  end
end

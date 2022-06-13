defmodule LibPE.FileTypeFlags do
  use LibPE.Flags
  # https://docs.microsoft.com/en-us/windows/win32/api/verrsrc/ns-verrsrc-vs_fixedfileinfo

  def flags() do
    [
      {"VFT_APP", 0x00000001, "The file contains an application."},
      {"VFT_DLL", 0x00000002, "The file contains a DLL."},
      {"VFT_DRV", 0x00000003,
       "The file contains a device driver. If dwFileType is VFT_DRV, dwFileSubtype contains a more specific description of the driver."},
      {"VFT_FONT", 0x00000004,
       "The file contains a font. If dwFileType is VFT_FONT, dwFileSubtype contains a more specific description of the font file."},
      {"VFT_STATIC_LIB", 0x00000007, "The file contains a static-link library."},
      {"VFT_UNKNOWN", 0x00000000, "The file type is unknown to the system."},
      {"VFT_VXD", 0x00000005, "The file contains a virtual device."}
    ]
  end
end

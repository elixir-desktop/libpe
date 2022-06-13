defmodule LibPE.FileSubtypeFlags do
  use LibPE.Flags
  # https://docs.microsoft.com/en-us/windows/win32/api/verrsrc/ns-verrsrc-vs_fixedfileinfo

  def flags() do
    [
      {"VFT2_UNKNOWN", 0x00000000, "Subtype is unknown."},

      # DRIVERS If dwFileType is VFT_DRV
      # {"VFT2_UNKNOWN", 0x00000000, "Driver type is unknown."},
      {"VFT2_DRV_COMM", 0x0000000A, "File contains a communications driver."},
      {"VFT2_DRV_PRINTER", 0x00000001, "File contains a printer driver."},
      {"VFT2_DRV_KEYBOARD", 0x00000002, "File contains a keyboard driver."},
      {"VFT2_DRV_LANGUAGE", 0x00000003, "File contains a language driver."},
      {"VFT2_DRV_DISPLAY", 0x00000004, "File contains a display driver."},
      {"VFT2_DRV_MOUSE", 0x00000005, "File contains a mouse driver."},
      {"VFT2_DRV_NETWORK", 0x00000006, "File contains a network driver."},
      {"VFT2_DRV_SYSTEM", 0x00000007, "File contains a system driver."},
      {"VFT2_DRV_INSTALLABLE", 0x00000008, "File contains an installable driver."},
      {"VFT2_DRV_SOUND", 0x00000009, "File contains a sound driver."},
      {"VFT2_DRV_VERSIONED_PRINTER", 0x0000000C, "File contains a versioned printer driver."},

      # FONTS If dwFileType is VFT_FONT
      # {"VFT2_UNKNOWN", 0x00000000, "The font type is unknown by the system."},
      {"VFT2_FONT_RASTER", 0x00000001, "File contains a raster font."},
      {"VFT2_FONT_VECTOR", 0x00000002, "File contains a vector font."},
      {"VFT2_FONT_TRUETYPE", 0x00000003, "File contains a TrueType font."}
    ]
  end
end

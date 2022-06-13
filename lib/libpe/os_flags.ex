defmodule LibPE.OSFlags do
  use LibPE.Flags
  # https://docs.microsoft.com/en-us/windows/win32/api/verrsrc/ns-verrsrc-vs_fixedfileinfo

  def flags() do
    [
      {"VOS_UNKNOWN", 0x00000000,
       "The operating system for which the file was designed is unknown."},
      {"VOS_DOS", 0x00010000, "File was designed for MS-DOS."},
      {"VOS_NT", 0x00040000, "File was designed for 32-bit Windows."},
      {"VOS__WINDOWS16", 0x00000001, "File was designed for 16-bit Windows."},
      {"VOS__WINDOWS32", 0x00000004, "File was designed for 32-bit Windows."},
      {"VOS_OS216", 0x00020000, "The file was designed for 16-bit OS/2."},
      {"VOS_OS232", 0x00030000, "The file was designed for 32-bit OS/2."},
      {"VOS__PM16", 0x00000002, "The file was designed for 16-bit Presentation Manager."},
      {"VOS__PM32", 0x00000003, "The file was designed for 32-bit Presentation Manager."},
      {"VOS_DOS_WINDOWS16", 0x00010001,
       "File was designed for 16-bit Windows running with MS-DOS."},
      {"VOS_DOS_WINDOWS32", 0x00010004,
       "File was designed for 32-bit Windows running with MS-DOS."},
      {"VOS_NT_WINDOWS32", 0x00040004, "File was designed for 32-bit Windows."},
      {"VOS_OS216_PM16", 0x00020002,
       " The file was designed for 16-bit Presentation Manager running on 16-bit OS/2."},
      {"VOS_OS232_PM32", 0x00030003,
       " The file was designed for 32-bit Presentation Manager running on 32-bit OS/2."}
    ]
  end
end

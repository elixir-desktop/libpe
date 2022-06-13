defmodule LibPE.FileFlags do
  use LibPE.Flags, [:many]
  # https://docs.microsoft.com/en-us/windows/win32/api/verrsrc/ns-verrsrc-vs_fixedfileinfo

  def flags() do
    [
      {"VS_FF_DEBUG", 0x00000001,
       "File contains debugging information or is compiled with debugging features enabled."},
      {"VS_FF_INFOINFERRED", 0x00000010,
       "The file's version structure was created dynamically; therefore, some of the members in this structure may be empty or incorrect. This flag should never be set in a file's VS_VERSIONINFO data."},
      {"VS_FF_PATCHED", 0x00000004,
       "File has been modified and is not identical to the original shipping file of the same version number."},
      {"VS_FF_PRERELEASE", 0x00000002,
       "File is a development version, not a commercially released product."},
      {"VS_FF_PRIVATEBUILD", 0x00000008,
       "File was not built using standard release procedures. If this value is given, the StringFileInfo block must contain a PrivateBuild string."},
      {"VS_FF_SPECIALBUILD", 0x00000020,
       "File was built by the original company using standard release procedures but is a variation of the standard file of the same version number. If this value is given, the StringFileInfo block block must contain a SpecialBuild string."}
      # {"VS_FFI_FILEFLAGSMASK", "A combination of all the preceding values."}
    ]
  end
end

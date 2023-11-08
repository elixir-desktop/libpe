defmodule LibPE.VersionInfo do
  alias LibPE.VersionInfo

  defstruct [
    :version_info,
    :version_info_raw,
    :var,
    :var_type,
    :strings,
    :strings_type,
    :strings_encoding,
    :type,
    :tail
  ]

  @moduledoc """
    Module to decode/encode RT_VERSION information in resources

    https://docs.microsoft.com/en-us/windows/win32/menurc/versioninfo-resource
    https://docs.microsoft.com/en-us/windows/win32/menurc/vs-versioninfo

    This is useful because it controls the company name and authors of a file
    when shown in file details and in the task manager
  """

  def new() do
    %LibPE.VersionInfo{
      version_info: %{
        dwStrucVersion: 1,
        dwFileVersionMS: 1_507_332,
        dwFileVersionLS: 196_622,
        dwProductVersionMS: 720_900,
        dwProductVersionLS: 65550,
        dwFileFlagsMask: 0,
        dwFileFlags: [],
        dwFileOS: "VOS_UNKNOWN",
        dwFileType: "VFT_UNKNOWN",
        dwFileSubtype: "VFT2_UNKNOWN",
        dwFileDate: 0
      },
      # magic constant https://learn.microsoft.com/en-us/windows/win32/menurc/versioninfo-resource
      strings_encoding: "040904e4",
      strings_type: 1,
      strings: [],
      var: <<9, 4, 228, 4>>,
      var_type: 0,
      tail: "",
      type: 0
    }
  end

  def decode(data) do
    <<_length::little-size(16), value_length::little-size(16), type::little-size(16),
      rest::binary>> = data

    # IO.inspect({length, value_length, type})
    {"VS_VERSION_INFO", rest} = decode_wchar(rest, "")

    rest = skip_padding(rest)
    <<file_info::binary-size(value_length), rest::binary>> = rest

    info = %VersionInfo{
      version_info: decode_version_info(file_info),
      version_info_raw: file_info,
      type: type
    }

    # there can be up to two
    {rest, info} = decode_children(skip_padding(rest), info)
    {rest, info} = decode_children(skip_padding(rest), info)
    %VersionInfo{info | tail: rest}
  end

  def encode(info = %VersionInfo{version_info: version_info, type: type, tail: tail}, offset \\ 0) do
    sz_key = encode_wchar("VS_VERSION_INFO")
    prefix_len = 6 + byte_size(sz_key)
    padding1 = maybe_padding(offset + prefix_len)
    file_info = encode_version_info(version_info)
    value_length = byte_size(file_info)
    padding2 = maybe_padding(offset + prefix_len + value_length + byte_size(padding1))

    children =
      encode_children(
        info,
        offset + prefix_len + value_length + byte_size(padding1) + byte_size(padding2)
      )

    length =
      prefix_len + value_length + byte_size(padding1) + byte_size(padding2) + byte_size(children)

    <<length::little-size(16), value_length::little-size(16), type::little-size(16),
      sz_key::binary, padding1::binary, file_info::binary, padding2::binary, children::binary,
      tail::binary>>
  end

  # https://docs.microsoft.com/en-us/windows/win32/api/verrsrc/ns-verrsrc-vs_fixedfileinfo
  defp decode_version_info(<<
         0xFEEF04BD::little-size(32),
         dwStrucVersion::little-size(32),
         dwFileVersionMS::little-size(32),
         dwFileVersionLS::little-size(32),
         dwProductVersionMS::little-size(32),
         dwProductVersionLS::little-size(32),
         dwFileFlagsMask::little-size(32),
         dwFileFlags::little-size(32),
         dwFileOS::little-size(32),
         dwFileType::little-size(32),
         dwFileSubtype::little-size(32),
         dwFileDate::little-size(64)
         #  dwFileDateMS::little-size(32),
         #  dwFileDateLS::little-size(32)
       >>) do
    %{
      # dwSignature: 0xFEEF04BD,
      dwStrucVersion: dwStrucVersion - 0xFFFF,
      dwFileVersionMS: dwFileVersionMS - 0xFFFF,
      dwFileVersionLS: dwFileVersionLS - 0xFFFF,
      dwProductVersionMS: dwProductVersionMS - 0xFFFF,
      dwProductVersionLS: dwProductVersionLS - 0xFFFF,
      dwFileFlagsMask: dwFileFlagsMask,
      dwFileFlags: LibPE.FileFlags.decode(dwFileFlags),
      dwFileOS: LibPE.OSFlags.decode(dwFileOS),
      dwFileType: LibPE.FileTypeFlags.decode(dwFileType),
      dwFileSubtype: LibPE.FileSubtypeFlags.decode(dwFileSubtype),
      dwFileDate: dwFileDate
    }
  end

  def encode_version_info(%{
        # dwSignature: 0xFEEF04BD,
        dwStrucVersion: dwStrucVersion,
        dwFileVersionMS: dwFileVersionMS,
        dwFileVersionLS: dwFileVersionLS,
        dwProductVersionMS: dwProductVersionMS,
        dwProductVersionLS: dwProductVersionLS,
        dwFileFlagsMask: dwFileFlagsMask,
        dwFileFlags: dwFileFlags,
        dwFileOS: dwFileOS,
        dwFileType: dwFileType,
        dwFileSubtype: dwFileSubtype,
        dwFileDate: dwFileDate
      }) do
    dwStrucVersion = dwStrucVersion + 0xFFFF
    dwFileVersionMS = dwFileVersionMS + 0xFFFF
    dwFileVersionLS = dwFileVersionLS + 0xFFFF
    dwProductVersionMS = dwProductVersionMS + 0xFFFF
    dwProductVersionLS = dwProductVersionLS + 0xFFFF
    dwFileFlags = LibPE.FileFlags.encode(dwFileFlags)
    dwFileOS = LibPE.OSFlags.encode(dwFileOS)
    dwFileType = LibPE.FileTypeFlags.encode(dwFileType)
    dwFileSubtype = LibPE.FileSubtypeFlags.encode(dwFileSubtype)

    <<
      0xFEEF04BD::little-size(32),
      dwStrucVersion::little-size(32),
      dwFileVersionMS::little-size(32),
      dwFileVersionLS::little-size(32),
      dwProductVersionMS::little-size(32),
      dwProductVersionLS::little-size(32),
      dwFileFlagsMask::little-size(32),
      dwFileFlags::little-size(32),
      dwFileOS::little-size(32),
      dwFileType::little-size(32),
      dwFileSubtype::little-size(32),
      dwFileDate::little-size(64)
      #  dwFileDateMS::little-size(32),
      #  dwFileDateLS::little-size(32)
    >>
  end

  # https://docs.microsoft.com/en-us/windows/win32/menurc/varfileinfo
  defp decode_children(
         <<length::little-size(16), _value_length::little-size(16), _type::little-size(16),
           rest::binary>>,
         info
       ) do
    children_length = length - 6
    <<children::binary-size(children_length), rest::binary>> = rest

    {sz_key, children} = decode_wchar(children, "")
    # IO.inspect({length, value_length, sz_key, type})
    children = skip_padding(children)

    case sz_key do
      "VarFileInfo" -> {rest, decode_var(children, info)}
      "StringFileInfo" -> {rest, decode_string_table(children, info)}
    end
  end

  defp encode_children(info = %VersionInfo{}, offset) do
    strings = wrap_child(info, "StringFileInfo", &encode_string_table/2, offset)
    padding1 = maybe_padding(offset + byte_size(strings))

    var =
      wrap_child(
        info,
        "VarFileInfo",
        &encode_var/2,
        offset + byte_size(strings) + byte_size(padding1)
      )

    <<strings::binary, padding1::binary, var::binary>>
  end

  defp decode_var(
         <<length::little-size(16), value_length::little-size(16), type::little-size(16),
           rest::binary>>,
         info
       ) do
    ^length = byte_size(rest) + 6
    {"Translation", rest} = decode_wchar(rest, "")
    rest = skip_padding(rest)
    # IO.inspect({:var, type, rest})
    ^value_length = byte_size(rest)
    %VersionInfo{info | var: rest, var_type: type}
  end

  defp wrap_child(info, name, fun, offset) do
    child_key = encode_wchar(name)
    padding1 = maybe_padding(offset + 6 + byte_size(child_key))
    offset = offset + 6 + byte_size(child_key) + byte_size(padding1)

    case fun.(info, offset) do
      "" ->
        ""

      bin ->
        length = 6 + byte_size(child_key) + byte_size(padding1) + byte_size(bin)
        value_length = 0
        type = 1

        <<length::little-size(16), value_length::little-size(16), type::little-size(16),
          child_key::binary, padding1::binary, bin::binary>>
    end
  end

  defp encode_var(%VersionInfo{var: nil}, _offset), do: ""

  defp encode_var(%VersionInfo{var: var, var_type: type}, offset) do
    sz_key = encode_wchar("Translation")
    padding1 = maybe_padding(offset + 6 + byte_size(sz_key))
    value_length = byte_size(var)
    length = 6 + byte_size(sz_key) + byte_size(padding1) + value_length

    <<length::little-size(16), value_length::little-size(16), type::little-size(16),
      sz_key::binary, padding1::binary, var::binary>>
  end

  # https://docs.microsoft.com/en-us/windows/win32/menurc/stringtable
  defp decode_string_table(
         <<length::little-size(16), 0::little-size(16), type::little-size(16), rest::binary>>,
         info
       ) do
    ^length = byte_size(rest) + 6
    {encoding, rest} = decode_wchar(rest, "")
    rest = skip_padding(rest)
    # IO.inspect({:var, type, sz_key, rest})
    %VersionInfo{
      info
      | strings: decode_strings(rest, encoding, []),
        strings_type: type,
        strings_encoding: encoding
    }
  end

  defp encode_string_table(
         %VersionInfo{strings: strings, strings_type: type, strings_encoding: encoding},
         offset
       ) do
    encoding = encode_wchar(encoding)
    padding1 = maybe_padding(offset + 6 + byte_size(encoding))

    rest =
      encode_strings(
        Enum.to_list(strings),
        encoding,
        offset + 6 + byte_size(encoding) + byte_size(padding1)
      )

    length = 6 + byte_size(encoding) + byte_size(padding1) + byte_size(rest)

    <<length::little-size(16), 0::little-size(16), type::little-size(16), encoding::binary,
      padding1::binary, rest::binary>>
  end

  defp decode_strings("", _encoding, strings) do
    strings
  end

  defp decode_strings(
         <<length::little-size(16), _value_length::little-size(16), _type::little-size(16),
           rest::binary>>,
         encoding,
         strings
       ) do
    string_length = length - 6
    # IO.inspect({string_length, byte_size(rest), rest})
    <<string::binary-size(string_length), rest::binary>> = rest
    {name, string} = decode_wchar(string, "")
    string = skip_padding(string)
    {value, _tail} = decode_wchar(string, "")
    # IO.inspect({name, value})
    decode_strings(skip_padding(rest), encoding, strings ++ [{name, value}])
  end

  defp encode_strings([{name, value} | rest], encoding, offset) do
    padding1 = maybe_padding(offset)
    name = encode_wchar(name)
    padding2 = maybe_padding(offset + 6 + byte_size(name) + byte_size(padding1))
    value = encode_wchar(value)
    length = 6 + byte_size(name) + byte_size(value) + byte_size(padding2)
    value_length = div(byte_size(value), 2)

    <<padding1::binary, length::little-size(16), value_length::little-size(16),
      1::little-size(16), name::binary, padding2::binary,
      value::binary>> <>
      encode_strings(rest, encoding, offset + length)
  end

  defp encode_strings([], _encoding, _offset) do
    ""
  end

  defp skip_padding(<<0, 0, rest::binary>>) do
    rest
  end

  defp skip_padding(<<other::binary>>) do
    other
  end

  defp maybe_padding(num) do
    if rem(num, 4) == 2, do: "\0\0", else: ""
  end

  defp decode_wchar(<<0, 0, rest::binary>>, str) do
    str = :unicode.characters_to_binary(str, {:utf16, :little}, :utf8)
    {str, rest}
  end

  defp decode_wchar(<<char::binary-size(2), rest::binary>>, str) do
    decode_wchar(rest, str <> char)
  end

  defp encode_wchar(utf8) do
    :unicode.characters_to_binary(utf8, :utf8, {:utf16, :little}) <> "\0\0"
  end

  def language_id() do
    [
      {0x0401, "Arabic"},
      {0x0402, "Bulgarian"},
      {0x0403, "Catalan"},
      {0x0404, "Traditional Chinese"},
      {0x0405, "Czech"},
      {0x0406, "Danish"},
      {0x0407, "German"},
      {0x0408, "Greek"},
      {0x0409, "U.S. English"},
      {0x040A, "Castilian Spanish"},
      {0x040B, "Finnish"},
      {0x040C, "French"},
      {0x040D, "Hebrew"},
      {0x040E, "Hungarian"},
      {0x040F, "Icelandic"},
      {0x0410, "Italian"},
      {0x0411, "Japanese"},
      {0x0412, "Korean"},
      {0x0413, "Dutch"},
      {0x0414, "Norwegian ? Bokmal"},
      {0x0415, "Polish"},
      {0x0416, "Portuguese (Brazil)"},
      {0x0417, "Rhaeto-Romanic"},
      {0x0418, "Romanian"},
      {0x0419, "Russian"},
      {0x041A, "Croato-Serbian (Latin)"},
      {0x041B, "Slovak"},
      {0x041C, "Albanian"},
      {0x041D, "Swedish"},
      {0x041E, "Thai"},
      {0x041F, "Turkish"},
      {0x0420, "Urdu"},
      {0x0421, "Bahasa"},
      {0x0804, "Simplified Chinese"},
      {0x0807, "Swiss German"},
      {0x0809, "U.K. English"},
      {0x080A, "Spanish (Mexico)"},
      {0x080C, "Belgian French"},
      {0x0810, "Swiss Italian"},
      {0x0813, "Belgian Dutch"},
      {0x0814, "Norwegian ? Nynorsk"},
      {0x0816, "Portuguese (Portugal)"},
      {0x081A, "Serbo-Croatian (Cyrillic)"},
      {0x0C0C, "Canadian French"},
      {0x100C, "Swiss French"}
    ]
  end

  def charset_id() do
    [
      {0, 0x0000, "7-bit ASCII"},
      {932, 0x03A4, "Japan (Shift ? JIS X-0208)"},
      {949, 0x03B5, "Korea (Shift ? KSC 5601)"},
      {950, 0x03B6, "Taiwan (Big5)"},
      {1200, 0x04B0, "Unicode"},
      {1250, 0x04E2, "Latin-2 (Eastern European)"},
      {1251, 0x04E3, "Cyrillic"},
      {1252, 0x04E4, "Multilingual"},
      {1253, 0x04E5, "Greek"},
      {1254, 0x04E6, "Turkish"},
      {1255, 0x04E7, "Hebrew"},
      {1256, 0x04E8, "Arabic"}
    ]
  end

  def string_name() do
    [
      {"Comments", "Additional information that should be displayed for diagnostic purposes."},
      {"CompanyName",
       "Company that produced the file—for example, Microsoft Corporation or Standard Microsystems Corporation, Inc. This string is required."},
      {"FileDescription",
       "File description to be presented to users. This string may be displayed in a list box when the user is choosing files to install—for example, Keyboard Driver for AT-Style Keyboards. This string is required."},
      {"FileVersion",
       "Version number of the file—for example, 3.10 or 5.00.RC2. This string is required."},
      {"InternalName",
       "Internal name of the file, if one exists—for example, a module name if the file is a dynamic-link library. If the file has no internal name, this string should be the original filename, without extension. This string is required."},
      {"LegalCopyright",
       "Copyright notices that apply to the file. This should include the full text of all notices, legal symbols, copyright dates, and so on. This string is optional."},
      {"LegalTrademarks",
       "Trademarks and registered trademarks that apply to the file. This should include the full text of all notices, legal symbols, trademark numbers, and so on. This string is optional."},
      {"OriginalFilename",
       "Original name of the file, not including a path. This information enables an application to determine whether a file has been renamed by a user. The format of the name depends on the file system for which the file was created. This string is required."},
      {"PrivateBuild",
       "Information about a private version of the file—for example, Built by TESTER1 on \\TESTBED. This string should be present only if VS_FF_PRIVATEBUILD is specified in the fileflags parameter of the root block."},
      {"ProductName",
       "Name of the product with which the file is distributed. This string is required."},
      {"ProductVersion",
       "Version of the product with which the file is distributed—for example, 3.10 or 5.00.RC2. This string is required."},
      {"SpecialBuild",
       "Text that specifies how this version of the file differs from the standard version—for example, Private build for TESTER1 solving mouse problems on M250 and M250E computers. This string should be present only if VS_FF_SPECIALBUILD is specified in the fileflags parameter of the root block."}
    ]
  end
end

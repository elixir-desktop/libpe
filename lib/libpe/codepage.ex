defmodule LibPE.Codepage do
  use LibPE.Flags

  @doc """
    Generated based on documentation. Used this snipper after copy paste:

    ```
      data = ... (copy pasted)
      String.split(data, "\n") |> Enum.map(fn str -> String.split(str, " ", parts: 3, trim: true) end) |> Enum.filter(fn x -> length(x) == 3 end) |> Enum.map(fn [id, name, desc] -> {name, String.to_integer(id), desc} end)
    ```
  """

  def flags() do
    [
      {"IBM037", 37, "IBM EBCDIC US-Canada"},
      {"IBM437", 437, "OEM United States"},
      {"IBM500", 500, "IBM EBCDIC International"},
      {"ASMO-708", 708, "Arabic (ASMO 708)"},
      {"Arabic", 709, "(ASMO-449+, BCON V4)"},
      {"Arabic", 710, "- Transparent Arabic"},
      {"DOS-720", 720, "Arabic (Transparent ASMO); Arabic (DOS)"},
      {"ibm737", 737, "OEM Greek (formerly 437G); Greek (DOS)"},
      {"ibm775", 775, "OEM Baltic; Baltic (DOS)"},
      {"ibm850", 850, "OEM Multilingual Latin 1; Western European (DOS)"},
      {"ibm852", 852, "OEM Latin 2; Central European (DOS)"},
      {"IBM855", 855, "OEM Cyrillic (primarily Russian)"},
      {"ibm857", 857, "OEM Turkish; Turkish (DOS)"},
      {"IBM00858", 858, "OEM Multilingual Latin 1 + Euro symbol"},
      {"IBM860", 860, "OEM Portuguese; Portuguese (DOS)"},
      {"ibm861", 861, "OEM Icelandic; Icelandic (DOS)"},
      {"DOS-862", 862, "OEM Hebrew; Hebrew (DOS)"},
      {"IBM863", 863, "OEM French Canadian; French Canadian (DOS)"},
      {"IBM864", 864, "OEM Arabic; Arabic (864)"},
      {"IBM865", 865, "OEM Nordic; Nordic (DOS)"},
      {"cp866", 866, "OEM Russian; Cyrillic (DOS)"},
      {"ibm869", 869, "OEM Modern Greek; Greek, Modern (DOS)"},
      {"IBM870", 870, "IBM EBCDIC Multilingual/ROECE (Latin 2); IBM EBCDIC Multilingual Latin 2"},
      {"windows-874", 874, "Thai (Windows)"},
      {"cp875", 875, "IBM EBCDIC Greek Modern"},
      {"shift_jis", 932, "ANSI/OEM Japanese; Japanese (Shift-JIS)"},
      {"gb2312", 936,
       "ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)"},
      {"ks_c_5601-1987", 949, "ANSI/OEM Korean (Unified Hangul Code)"},
      {"big5", 950,
       "ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)"},
      {"IBM1026", 1026, "IBM EBCDIC Turkish (Latin 5)"},
      {"IBM01047", 1047, "IBM EBCDIC Latin 1/Open System"},
      {"IBM01140", 1140, "IBM EBCDIC US-Canada (037 + Euro symbol); IBM EBCDIC (US-Canada-Euro)"},
      {"IBM01141", 1141, "IBM EBCDIC Germany (20273 + Euro symbol); IBM EBCDIC (Germany-Euro)"},
      {"IBM01142", 1142,
       "IBM EBCDIC Denmark-Norway (20277 + Euro symbol); IBM EBCDIC (Denmark-Norway-Euro)"},
      {"IBM01143", 1143,
       "IBM EBCDIC Finland-Sweden (20278 + Euro symbol); IBM EBCDIC (Finland-Sweden-Euro)"},
      {"IBM01144", 1144, "IBM EBCDIC Italy (20280 + Euro symbol); IBM EBCDIC (Italy-Euro)"},
      {"IBM01145", 1145,
       "IBM EBCDIC Latin America-Spain (20284 + Euro symbol); IBM EBCDIC (Spain-Euro)"},
      {"IBM01146", 1146, "IBM EBCDIC United Kingdom (20285 + Euro symbol); IBM EBCDIC (UK-Euro)"},
      {"IBM01147", 1147, "IBM EBCDIC France (20297 + Euro symbol); IBM EBCDIC (France-Euro)"},
      {"IBM01148", 1148,
       "IBM EBCDIC International (500 + Euro symbol); IBM EBCDIC (International-Euro)"},
      {"IBM01149", 1149,
       "IBM EBCDIC Icelandic (20871 + Euro symbol); IBM EBCDIC (Icelandic-Euro)"},
      {"utf-16", 1200,
       "Unicode UTF-16, little endian byte order (BMP of ISO 10646); available only to managed applications"},
      {"unicodeFFFE", 1201,
       "Unicode UTF-16, big endian byte order; available only to managed applications"},
      {"windows-1250", 1250, "ANSI Central European; Central European (Windows)"},
      {"windows-1251", 1251, "ANSI Cyrillic; Cyrillic (Windows)"},
      {"windows-1252", 1252, "ANSI Latin 1; Western European (Windows)"},
      {"windows-1253", 1253, "ANSI Greek; Greek (Windows)"},
      {"windows-1254", 1254, "ANSI Turkish; Turkish (Windows)"},
      {"windows-1255", 1255, "ANSI Hebrew; Hebrew (Windows)"},
      {"windows-1256", 1256, "ANSI Arabic; Arabic (Windows)"},
      {"windows-1257", 1257, "ANSI Baltic; Baltic (Windows)"},
      {"windows-1258", 1258, "ANSI/OEM Vietnamese; Vietnamese (Windows)"},
      {"Johab", 1361, "Korean (Johab)"},
      {"macintosh", 10000, "MAC Roman; Western European (Mac)"},
      {"x-mac-japanese", 10001, "Japanese (Mac)"},
      {"x-mac-chinesetrad", 10002, "MAC Traditional Chinese (Big5); Chinese Traditional (Mac)"},
      {"x-mac-korean", 10003, "Korean (Mac)"},
      {"x-mac-arabic", 10004, "Arabic (Mac)"},
      {"x-mac-hebrew", 10005, "Hebrew (Mac)"},
      {"x-mac-greek", 10006, "Greek (Mac)"},
      {"x-mac-cyrillic", 10007, "Cyrillic (Mac)"},
      {"x-mac-chinesesimp", 10008, "MAC Simplified Chinese (GB 2312); Chinese Simplified (Mac)"},
      {"x-mac-romanian", 10010, "Romanian (Mac)"},
      {"x-mac-ukrainian", 10017, "Ukrainian (Mac)"},
      {"x-mac-thai", 10021, "Thai (Mac)"},
      {"x-mac-ce", 10029, "MAC Latin 2; Central European (Mac)"},
      {"x-mac-icelandic", 10079, "Icelandic (Mac)"},
      {"x-mac-turkish", 10081, "Turkish (Mac)"},
      {"x-mac-croatian", 10082, "Croatian (Mac)"},
      {"utf-32", 12000,
       "Unicode UTF-32, little endian byte order; available only to managed applications"},
      {"utf-32BE", 12001,
       "Unicode UTF-32, big endian byte order; available only to managed applications"},
      {"x-Chinese_CNS", 20000, "CNS Taiwan; Chinese Traditional (CNS)"},
      {"x-cp20001", 20001, "TCA Taiwan"},
      {"x_Chinese-Eten", 20002, "Eten Taiwan; Chinese Traditional (Eten)"},
      {"x-cp20003", 20003, "IBM5550 Taiwan"},
      {"x-cp20004", 20004, "TeleText Taiwan"},
      {"x-cp20005", 20005, "Wang Taiwan"},
      {"x-IA5", 20105, "IA5 (IRV International Alphabet No. 5, 7-bit); Western European (IA5)"},
      {"x-IA5-German", 20106, "IA5 German (7-bit)"},
      {"x-IA5-Swedish", 20107, "IA5 Swedish (7-bit)"},
      {"x-IA5-Norwegian", 20108, "IA5 Norwegian (7-bit)"},
      {"us-ascii", 20127, "US-ASCII (7-bit)"},
      {"x-cp20261", 20261, "T.61"},
      {"x-cp20269", 20269, "ISO 6937 Non-Spacing Accent"},
      {"IBM273", 20273, "IBM EBCDIC Germany"},
      {"IBM277", 20277, "IBM EBCDIC Denmark-Norway"},
      {"IBM278", 20278, "IBM EBCDIC Finland-Sweden"},
      {"IBM280", 20280, "IBM EBCDIC Italy"},
      {"IBM284", 20284, "IBM EBCDIC Latin America-Spain"},
      {"IBM285", 20285, "IBM EBCDIC United Kingdom"},
      {"IBM290", 20290, "IBM EBCDIC Japanese Katakana Extended"},
      {"IBM297", 20297, "IBM EBCDIC France"},
      {"IBM420", 20420, "IBM EBCDIC Arabic"},
      {"IBM423", 20423, "IBM EBCDIC Greek"},
      {"IBM424", 20424, "IBM EBCDIC Hebrew"},
      {"x-EBCDIC-KoreanExtended", 20833, "IBM EBCDIC Korean Extended"},
      {"IBM-Thai", 20838, "IBM EBCDIC Thai"},
      {"koi8-r", 20866, "Russian (KOI8-R); Cyrillic (KOI8-R)"},
      {"IBM871", 20871, "IBM EBCDIC Icelandic"},
      {"IBM880", 20880, "IBM EBCDIC Cyrillic Russian"},
      {"IBM905", 20905, "IBM EBCDIC Turkish"},
      {"IBM00924", 20924, "IBM EBCDIC Latin 1/Open System (1047 + Euro symbol)"},
      {"EUC-JP", 20932, "Japanese (JIS 0208-1990 and 0212-1990)"},
      {"x-cp20936", 20936, "Simplified Chinese (GB2312); Chinese Simplified (GB2312-80)"},
      {"x-cp20949", 20949, "Korean Wansung"},
      {"cp1025", 21025, "IBM EBCDIC Cyrillic Serbian-Bulgarian"},
      {"(deprecated)", 21027, "Deprecated"},
      {"koi8-u", 21866, "Ukrainian (KOI8-U); Cyrillic (KOI8-U)"},
      {"iso-8859-1", 28591, "ISO 8859-1 Latin 1; Western European (ISO)"},
      {"iso-8859-2", 28592, "ISO 8859-2 Central European; Central European (ISO)"},
      {"iso-8859-3", 28593, "ISO 8859-3 Latin 3"},
      {"iso-8859-4", 28594, "ISO 8859-4 Baltic"},
      {"iso-8859-5", 28595, "ISO 8859-5 Cyrillic"},
      {"iso-8859-6", 28596, "ISO 8859-6 Arabic"},
      {"iso-8859-7", 28597, "ISO 8859-7 Greek"},
      {"iso-8859-8", 28598, "ISO 8859-8 Hebrew; Hebrew (ISO-Visual)"},
      {"iso-8859-9", 28599, "ISO 8859-9 Turkish"},
      {"iso-8859-13", 28603, "ISO 8859-13 Estonian"},
      {"iso-8859-15", 28605, "ISO 8859-15 Latin 9"},
      {"x-Europa", 29001, "Europa 3"},
      {"iso-8859-8-i", 38598, "ISO 8859-8 Hebrew; Hebrew (ISO-Logical)"},
      {"iso-2022-jp", 50220, "ISO 2022 Japanese with no halfwidth Katakana; Japanese (JIS)"},
      {"csISO2022JP", 50221,
       "ISO 2022 Japanese with halfwidth Katakana; Japanese (JIS-Allow 1 byte Kana)"},
      {"iso-2022-jp", 50222,
       "ISO 2022 Japanese JIS X 0201-1989; Japanese (JIS-Allow 1 byte Kana - SO/SI)"},
      {"iso-2022-kr", 50225, "ISO 2022 Korean"},
      {"x-cp50227", 50227, "ISO 2022 Simplified Chinese; Chinese Simplified (ISO 2022)"},
      {"ISO", 50229, "2022 Traditional Chinese"},
      {"EBCDIC", 50930, "Japanese (Katakana) Extended"},
      {"EBCDIC", 50931, "US-Canada and Japanese"},
      {"EBCDIC", 50933, "Korean Extended and Korean"},
      {"EBCDIC", 50935, "Simplified Chinese Extended and Simplified Chinese"},
      {"EBCDIC", 50936, "Simplified Chinese"},
      {"EBCDIC", 50937, "US-Canada and Traditional Chinese"},
      {"EBCDIC", 50939, "Japanese (Latin) Extended and Japanese"},
      {"euc-jp", 51932, "EUC Japanese"},
      {"EUC-CN", 51936, "EUC Simplified Chinese; Chinese Simplified (EUC)"},
      {"euc-kr", 51949, "EUC Korean"},
      {"EUC", 51950, "Traditional Chinese"},
      {"hz-gb-2312", 52936, "HZ-GB2312 Simplified Chinese; Chinese Simplified (HZ)"},
      {"GB18030", 54936,
       "Windows XP and later: GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)"},
      {"x-iscii-de", 57002, "ISCII Devanagari"},
      {"x-iscii-be", 57003, "ISCII Bangla"},
      {"x-iscii-ta", 57004, "ISCII Tamil"},
      {"x-iscii-te", 57005, "ISCII Telugu"},
      {"x-iscii-as", 57006, "ISCII Assamese"},
      {"x-iscii-or", 57007, "ISCII Odia"},
      {"x-iscii-ka", 57008, "ISCII Kannada"},
      {"x-iscii-ma", 57009, "ISCII Malayalam"},
      {"x-iscii-gu", 57010, "ISCII Gujarati"},
      {"x-iscii-pa", 57011, "ISCII Punjabi"},
      {"utf-7", 65000, "Unicode (UTF-7)"},
      {"utf-8", 65001, "Unicode (UTF-8)"}
    ]
  end
end

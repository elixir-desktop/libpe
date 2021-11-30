defmodule LibPE.Language do
  alias LibPE.Flags

  @doc """
    Generated based on documentation. Used this snipper after copy paste:

    ```
      data = ... (copy pasted)
      Enum.chunk_every(String.split(data, "\n"), 3, 3, :discard) |> Enum.map(fn [name, id, desc] -> {name, String.to_integer(id), desc} end)
    ```
  """

  def flags() do
    [
      {"ar-SA", 1025, "Arabic - Saudi Arabia"},
      {"bg-BG", 1026, "Bulgarian"},
      {"ca-ES", 1027, "Catalan"},
      {"zh-TW", 1028, "Chinese - Taiwan"},
      {"cs-CZ", 1029, "Czech"},
      {"da-DK", 1030, "Danish"},
      {"de-DE", 1031, "German - Germany"},
      {"el-GR", 1032, "Greek"},
      {"en-US", 1033, "English - United States"},
      {"es-ES", 1034, "Spanish - Spain (Traditional Sort)"},
      {"fi-FI", 1035, "Finnish"},
      {"fr-FR", 1036, "French - France"},
      {"he-IL", 1037, "Hebrew"},
      {"hu-HU", 1038, "Hungarian"},
      {"is-IS", 1039, "Icelandic"},
      {"it-IT", 1040, "Italian - Italy"},
      {"ja-JP", 1041, "Japanese"},
      {"ko-KR", 1042, "Korean"},
      {"nl-NL", 1043, "Dutch - Netherlands"},
      {"nb-NO", 1044, "Norwegian (Bokmål)"},
      {"pl-PL", 1045, "Polish"},
      {"pt-BR", 1046, "Portuguese - Brazil"},
      {"rm-CH", 1047, "Rhaeto-Romanic"},
      {"ro-RO", 1048, "Romanian"},
      {"ru-RU", 1049, "Russian"},
      {"hr-HR", 1050, "Croatian"},
      {"sk-SK", 1051, "Slovak"},
      {"sq-AL", 1052, "Albanian - Albania"},
      {"sv-SE", 1053, "Swedish"},
      {"th-TH", 1054, "Thai"},
      {"tr-TR", 1055, "Turkish"},
      {"ur-PK", 1056, "Urdu - Pakistan"},
      {"id-ID", 1057, "Indonesian"},
      {"uk-UA", 1058, "Ukrainian"},
      {"be-BY", 1059, "Belarusian"},
      {"sl-SI", 1060, "Slovenian"},
      {"et-EE", 1061, "Estonian"},
      {"lv-LV", 1062, "Latvian"},
      {"lt-LT", 1063, "Lithuanian"},
      {"tg-Cyrl-TJ", 1064, "Tajik"},
      {"fa-IR", 1065, "Persian"},
      {"vi-VN", 1066, "Vietnamese"},
      {"hy-AM", 1067, "Armenian - Armenia"},
      {"az-Latn-AZ", 1068, "Azeri (Latin)"},
      {"eu-ES", 1069, "Basque"},
      {"wen-DE", 1070, "Sorbian"},
      {"mk-MK", 1071, "F.Y.R.O. Macedonian"},
      {"st-ZA", 1072, "Sutu"},
      {"ts-ZA", 1073, "Tsonga"},
      {"tn-ZA", 1074, "Tswana"},
      {"ven-ZA", 1075, "Venda"},
      {"xh-ZA", 1076, "Xhosa"},
      {"zu-ZA", 1077, "Zulu"},
      {"af-ZA", 1078, "Afrikaans - South Africa"},
      {"ka-GE", 1079, "Georgian"},
      {"fo-FO", 1080, "Faroese"},
      {"hi-IN", 1081, "Hindi"},
      {"mt-MT", 1082, "Maltese"},
      {"se-NO", 1083, "Sami"},
      {"gd-GB", 1084, "Gaelic (Scotland)"},
      {"yi", 1085, "Yiddish"},
      {"ms-MY", 1086, "Malay - Malaysia"},
      {"kk-KZ", 1087, "Kazakh"},
      {"ky-KG", 1088, "Kyrgyz (Cyrillic)"},
      {"sw-KE", 1089, "Swahili"},
      {"tk-TM", 1090, "Turkmen"},
      {"uz-Latn-UZ", 1091, "Uzbek (Latin)"},
      {"tt-RU", 1092, "Tatar"},
      {"bn-IN", 1093, "Bengali (India)"},
      {"pa-IN", 1094, "Punjabi"},
      {"gu-IN", 1095, "Gujarati"},
      {"or-IN", 1096, "Oriya"},
      {"ta-IN", 1097, "Tamil"},
      {"te-IN", 1098, "Telugu"},
      {"kn-IN", 1099, "Kannada"},
      {"st-ZA", 1072, "Sutu"},
      {"ts-ZA", 1073, "Tsonga"},
      {"tn-ZA", 1074, "Tswana"},
      {"ven-ZA", 1075, "Venda"},
      {"xh-ZA", 1076, "Xhosa"},
      {"zu-ZA", 1077, "Zulu"},
      {"af-ZA", 1078, "Afrikaans - South Africa"},
      {"ka-GE", 1079, "Georgian"},
      {"fo-FO", 1080, "Faroese"},
      {"hi-IN", 1081, "Hindi"},
      {"mt-MT", 1082, "Maltese"},
      {"se-NO", 1083, "Sami"},
      {"gd-GB", 1084, "Gaelic (Scotland)"},
      {"yi", 1085, "Yiddish"},
      {"ms-MY", 1086, "Malay - Malaysia"},
      {"kk-KZ", 1087, "Kazakh"},
      {"ky-KG", 1088, "Kyrgyz (Cyrillic)"},
      {"sw-KE", 1089, "Swahili"},
      {"tk-TM", 1090, "Turkmen"},
      {"uz-Latn-UZ", 1091, "Uzbek (Latin)"},
      {"tt-RU", 1092, "Tatar"},
      {"bn-IN", 1093, "Bengali (India)"},
      {"pa-IN", 1094, "Punjabi"},
      {"gu-IN", 1095, "Gujarati"},
      {"or-IN", 1096, "Oriya"},
      {"ta-IN", 1097, "Tamil"},
      {"te-IN", 1098, "Telugu"},
      {"kn-IN", 1099, "Kannada"},
      {"ml-IN", 1100, "Malayalam"},
      {"as-IN", 1101, "Assamese"},
      {"ml-IN", 1100, "Malayalam"},
      {"as-IN", 1101, "Assamese"},
      {"mr-IN", 1102, "Marathi"},
      {"sa-IN", 1103, "Sanskrit"},
      {"mn-MN", 1104, "Mongolian (Cyrillic)"},
      {"bo-CN", 1105, "Tibetan - People's Republic of China"},
      {"cy-GB", 1106, "Welsh"},
      {"km-KH", 1107, "Khmer"},
      {"lo-LA", 1108, "Lao"},
      {"my-MM", 1109, "Burmese"},
      {"gl-ES", 1110, "Galician"},
      {"kok-IN", 1111, "Konkani"},
      {"mni", 1112, "Manipuri"},
      {"sd-IN", 1113, "Sindhi - India"},
      {"syr-SY", 1114, "Syriac"},
      {"si-LK", 1115, "Sinhalese - Sri Lanka"},
      {"chr-US", 1116, "Cherokee - United States"},
      {"iu-Cans-CA", 1117, "Inuktitut"},
      {"am-ET", 1118, "Amharic - Ethiopia"},
      {"tmz", 1119, "Tamazight (Arabic)"},
      {"ks-Arab-IN", 1120, "Kashmiri (Arabic)"},
      {"ne-NP", 1121, "Nepali"},
      {"fy-NL", 1122, "Frisian - Netherlands"},
      {"ps-AF", 1123, "Pashto"},
      {"fil-PH", 1124, "Filipino"},
      {"dv-MV", 1125, "Divehi"},
      {"bin-NG", 1126, "Edo"},
      {"fuv-NG", 1127, "Fulfulde - Nigeria"},
      {"ha-Latn-NG", 1128, "Hausa - Nigeria"},
      {"ibb-NG", 1129, "Ibibio - Nigeria"},
      {"yo-NG", 1130, "Yoruba"},
      {"quz-BO", 1131, "Quecha - Bolivia"},
      {"nso-ZA", 1132, "Sepedi"},
      {"ig-NG", 1136, "Igbo - Nigeria"},
      {"kr-NG", 1137, "Kanuri - Nigeria"},
      {"gaz-ET", 1138, "Oromo"},
      {"ti-ER", 1139, "Tigrigna - Ethiopia"},
      {"gn-PY", 1140, "Guarani - Paraguay"},
      {"haw-US", 1141, "Hawaiian - United States"},
      {"la", 1142, "Latin"},
      {"so-SO", 1143, "Somali"},
      {"ii-CN", 1144, "Yi"},
      {"pap-AN", 1145, "Papiamentu"},
      {"ug-Arab-CN", 1152, "Uighur - China"},
      {"mi-NZ", 1153, "Maori - New Zealand"},
      {"ar-IQ", 2049, "Arabic - Iraq"},
      {"zh-CN", 2052, "Chinese - People's Republic of China"},
      {"de-CH", 2055, "German - Switzerland"},
      {"en-GB", 2057, "English - United Kingdom"},
      {"es-MX", 2058, "Spanish - Mexico"},
      {"fr-BE", 2060, "French - Belgium"},
      {"it-CH", 2064, "Italian - Switzerland"},
      {"nl-BE", 2067, "Dutch - Belgium"},
      {"nn-NO", 2068, "Norwegian (Nynorsk)"},
      {"pt-PT", 2070, "Portuguese - Portugal"},
      {"ro-MD", 2072, "Romanian - Moldava"},
      {"ru-MD", 2073, "Russian - Moldava"},
      {"sr-Latn-CS", 2074, "Serbian (Latin)"},
      {"sv-FI", 2077, "Swedish - Finland"},
      {"ur-IN", 2080, "Urdu - India"},
      {"az-Cyrl-AZ", 2092, "Azeri (Cyrillic)"},
      {"ga-IE", 2108, "Gaelic (Ireland)"},
      {"ms-BN", 2110, "Malay - Brunei Darussalam"},
      {"uz-Cyrl-UZ", 2115, "Uzbek (Cyrillic)"},
      {"bn-BD", 2117, "Bengali (Bangladesh)"},
      {"pa-PK", 2118, "Punjabi (Pakistan)"},
      {"mn-Mong-CN", 2128, "Mongolian (Mongolian)"},
      {"bo-BT", 2129, "Tibetan - Bhutan"},
      {"sd-PK", 2137, "Sindhi - Pakistan"},
      {"tzm-Latn-DZ", 2143, "Tamazight (Latin)"},
      {"ks-Deva-IN", 2144, "Kashmiri (Devanagari)"},
      {"ne-IN", 2145, "Nepali - India"},
      {"quz-EC", 2155, "Quecha - Ecuador"},
      {"ti-ET", 2163, "Tigrigna - Eritrea"},
      {"ar-EG", 3073, "Arabic - Egypt"},
      {"zh-HK", 3076, "Chinese - Hong Kong SAR"},
      {"de-AT", 3079, "German - Austria"},
      {"en-AU", 3081, "English - Australia"},
      {"es-ES", 3082, "Spanish - Spain (Modern Sort)"},
      {"fr-CA", 3084, "French - Canada"},
      {"sr-Cyrl-CS", 3098, "Serbian (Cyrillic)"},
      {"quz-PE", 3179, "Quecha - Peru"},
      {"ar-LY", 4097, "Arabic - Libya"},
      {"zh-SG", 4100, "Chinese - Singapore"},
      {"de-LU", 4103, "German - Luxembourg"},
      {"en-CA", 4105, "English - Canada"},
      {"es-GT", 4106, "Spanish - Guatemala"},
      {"fr-CH", 4108, "French - Switzerland"},
      {"hr-BA", 4122, "Croatian (Bosnia/Herzegovina)"},
      {"ar-DZ", 5121, "Arabic - Algeria"},
      {"zh-MO", 5124, "Chinese - Macao SAR"},
      {"de-LI", 5127, "German - Liechtenstein"},
      {"en-NZ", 5129, "English - New Zealand"},
      {"es-CR", 5130, "Spanish - Costa Rica"},
      {"fr-LU", 5132, "French - Luxembourg"},
      {"bs-Latn-BA", 5146, "Bosnian (Bosnia/Herzegovina)"},
      {"ar-MO", 6145, "Arabic - Morocco"},
      {"en-IE", 6153, "English - Ireland"},
      {"es-PA", 6154, "Spanish - Panama"},
      {"fr-MC", 6156, "French - Monaco"},
      {"ar-TN", 7169, "Arabic - Tunisia"},
      {"en-ZA", 7177, "English - South Africa"},
      {"es-DO", 7178, "Spanish - Dominican Republic"},
      {"fr-029", 7180, "French - West Indies"},
      {"ar-OM", 8193, "Arabic - Oman"},
      {"en-JM", 8201, "English - Jamaica"},
      {"es-VE", 8202, "Spanish - Venezuela"},
      {"fr-RE", 8204, "French - Reunion"},
      {"ar-YE", 9217, "Arabic - Yemen"},
      {"en-029", 9225, "English - Caribbean"},
      {"es-CO", 9226, "Spanish - Colombia"},
      {"fr-CG", 9228, "French - Democratic Rep. of Congo"},
      {"ar-SY", 10241, "Arabic - Syria"},
      {"en-BZ", 10249, "English - Belize"},
      {"es-PE", 10250, "Spanish - Peru"},
      {"fr-SN", 10252, "French - Senegal"},
      {"ar-JO", 11265, "Arabic - Jordan"},
      {"en-TT", 11273, "English - Trinidad"},
      {"es-AR", 11274, "Spanish - Argentina"},
      {"fr-CM", 11276, "French - Cameroon"},
      {"ar-LB", 12289, "Arabic - Lebanon"},
      {"en-ZW", 12297, "English - Zimbabwe"},
      {"es-EC", 12298, "Spanish - Ecuador"},
      {"fr-CI", 12300, "French - Cote d'Ivoire"},
      {"ar-KW", 13313, "Arabic - Kuwait"},
      {"en-PH", 13321, "English - Philippines"},
      {"es-CL", 13322, "Spanish - Chile"},
      {"fr-ML", 13324, "French - Mali"},
      {"ar-AE", 14337, "Arabic - U.A.E."},
      {"en-ID", 14345, "English - Indonesia"},
      {"es-UY", 14346, "Spanish - Uruguay"},
      {"fr-MA", 14348, "French - Morocco"},
      {"ar-BH", 15361, "Arabic - Bahrain"},
      {"en-HK", 15369, "English - Hong Kong SAR"},
      {"es-PY", 15370, "Spanish - Paraguay"},
      {"fr-HT", 15372, "French - Haiti"},
      {"ar-QA", 16385, "Arabic - Qatar"},
      {"en-IN", 16393, "English - India"},
      {"es-BO", 16394, "Spanish - Bolivia"},
      {"en-MY", 17417, "English - Malaysia"},
      {"es-SV", 17418, "Spanish - El Salvador"},
      {"en-SG", 18441, "English - Singapore"},
      {"es-HN", 18442, "Spanish - Honduras"},
      {"es-NI", 19466, "Spanish - Nicaragua"},
      {"es-PR", 20490, "Spanish - Puerto Rico"},
      {"es-US", 21514, "Spanish - United States"},
      {"es-419", 58378, "Spanish - Latin America"},
      {"fr-015", 58380, "French - North Africa"}
    ]
  end

  def decode(flag) do
    Flags.decode(__MODULE__, flag)
  end

  def encode(flag) do
    Flags.encode(__MODULE__, flag)
  end
end

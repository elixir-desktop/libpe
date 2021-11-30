defmodule LibPE.ResourceTypes do
  @doc """
    Generated based on documentation. Used this snipper after copy paste:

    ```
      data = ... (copy pasted)
      Enum.chunk_every(String.split(data, "\n"), 5, 5, :discard) |> Enum.map(fn [_, name, id, _, desc] -> {name, Regex.replace(~r/MAKEINTRESOURCE\(([0-9]+)\)/, id, "\\1"), desc} end)
    ```
  """
  alias LibPE.Flags

  def flags() do
    [
      {"RT_ACCELERATOR", 9, "Accelerator table."},
      {"RT_ANICURSOR", 21, "Animated cursor."},
      {"RT_ANIICON", 22, "Animated icon."},
      {"RT_BITMAP", 2, "Bitmap resource."},
      {"RT_CURSOR", 1, "Hardware-dependent cursor resource."},
      {"RT_DIALOG", 5, "Dialog box."},
      {"RT_DLGINCLUDE", 17,
       "Allows a resource editing tool to associate a string with an .rc file. Typically, the string is the name of the header file that provides symbolic names. The resource compiler parses the string but otherwise ignores the value. For example,"},
      {"RT_FONT", 8, "Font resource."},
      {"RT_FONTDIR", 7, "Font directory resource."},
      {"RT_GROUP_CURSOR", 12, "Hardware-independent cursor resource."},
      {"RT_GROUP_ICON", 14, "Hardware-independent icon resource."},
      {"RT_HTML", 23, "HTML resource."},
      {"RT_ICON", 3, "Hardware-dependent icon resource."},
      {"RT_MANIFEST", 24, "Side-by-Side Assembly Manifest."},
      {"RT_MENU", 4, "Menu resource."},
      {"RT_MESSAGETABLE", 11, "Message-table entry."},
      {"RT_PLUGPLAY", 19, "Plug and Play resource."},
      {"RT_RCDATA", 10, "Application-defined resource (raw data)."},
      {"RT_STRING", 6, "String-table entry."},
      {"RT_VERSION", 16, "Version resource."},
      {"RT_VXD", 20, "VXD."}
    ]
  end

  def decode(id) do
    Flags.decode(__MODULE__, id)
  end

  def encode(id) do
    Flags.encode(__MODULE__, id)
  end
end

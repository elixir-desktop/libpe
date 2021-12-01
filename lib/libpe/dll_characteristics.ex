defmodule LibPE.DLLCharacteristics do
  use LibPE.Flags, [:many]

  @moduledoc """

    Generated based on documentation. Used this snipper after copy paste:

    ```
      data = ... (copy pasted)
      Enum.chunk_every(String.split(data, "\n"), 3, 3, :discard) |> Enum.map(fn [name, <<"0x",id :: binary>>, desc] -> {name, elem(Integer.parse(id, 16), 0), desc} end)
    ```
  """

  def flags() do
    [
      {"", 1, "Reserved, must be zero."},
      {"", 2, "Reserved, must be zero."},
      {"", 4, "Reserved, must be zero."},
      {"", 8, "Reserved, must be zero."},
      {"IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA", 32,
       "Image can handle a high entropy 64-bit virtual address space."},
      {"IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE", 64, "DLL can be relocated at load time."},
      {"IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY", 128, "Code Integrity checks are enforced."},
      {"IMAGE_DLLCHARACTERISTICS_NX_COMPAT", 256, "Image is NX compatible."},
      {"IMAGE_DLLCHARACTERISTICS_NO_ISOLATION", 512,
       "Isolation aware, but do not isolate the image."},
      {"IMAGE_DLLCHARACTERISTICS_NO_SEH", 1024,
       "Does not use structured exception (SE) handling. No SE handler may be called in this image."},
      {"IMAGE_DLLCHARACTERISTICS_NO_BIND", 2048, "Do not bind the image."},
      {"IMAGE_DLLCHARACTERISTICS_APPCONTAINER", 4096, "Image must execute in an AppContainer."},
      {"IMAGE_DLLCHARACTERISTICS_WDM_DRIVER", 8192, "A WDM driver."},
      {"IMAGE_DLLCHARACTERISTICS_GUARD_CF", 16384, "Image supports Control Flow Guard."},
      {"IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE", 32768, "Terminal Server aware. "}
    ]
  end
end

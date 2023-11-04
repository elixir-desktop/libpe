defmodule LibPETest do
  use ExUnit.Case
  doctest LibPE

  test "test open file" do
    for filename <- test_files() do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      reencoded = LibPE.encode(pe)
      assert byte_size(raw) == byte_size(reencoded)
      assert :crypto.hash(:sha, raw) == :crypto.hash(:sha, reencoded)
      assert pe.coff_header.checksum == LibPE.update_checksum(pe).coff_header.checksum
    end
  end

  test "test version encode/decode" do
    for filename <- test_files() do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)
      resource_table = LibPE.get_resources(pe)
      version = LibPE.ResourceTable.get_resource(resource_table, "RT_VERSION")

      if version != nil do
        info = LibPE.VersionInfo.decode(version.entry.data)
        assert LibPE.VersionInfo.encode_version_info(info.version_info) == info.version_info_raw
        assert dump16(LibPE.VersionInfo.encode(info)) == dump16(version.entry.data)
      end
    end
  end

  defp dump16(bin) do
    for <<a, b <- bin>> do
      case <<a, b>> do
        <<a, 0>> -> if String.printable?(<<a>>), do: <<a>>, else: "[#{a}]"
        <<x::little-size(16)>> -> "#{x},"
      end
    end
    |> Enum.join()
  end

  test "test update file" do
    for filename <- test_files() do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      assert clean_data(pe) == clean_data(LibPE.update_layout(pe))
    end
  end

  test "test parse resources" do
    for filename <- test_files() do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      resources = Enum.find(pe.coff_sections, fn sec -> sec.name == ".rsrc" end)

      rsrc = LibPE.ResourceTable.parse(resources.virtual_data, resources.virtual_address)

      LibPE.ResourceTable.dump(rsrc)

      resources2 = LibPE.ResourceTable.encode(rsrc, resources.virtual_address)
      rsrc2 = LibPE.ResourceTable.parse(resources2, resources.virtual_address)

      assert clean_data(rsrc) == clean_data(rsrc2)
      # assert byte_size(resources.virtual_data) == byte_size(resources2)
      # assert resources.virtual_data == resources2
      # assert clean_data(rsrc) == clean_data(rsrc2)
    end
  end

  test "set icon" do
    {:ok, pe} = LibPE.parse_file("test/hello.exe")

    resource_table = LibPE.get_resources(pe)

    data = File.read!("test/logo.ico")
    type = LibPE.ResourceTypes.encode("RT_ICON")
    resource_table = LibPE.ResourceTable.set_resource(resource_table, type, data)

    raw =
      LibPE.set_resources(pe, resource_table)
      |> LibPE.update_layout()
      |> LibPE.update_checksum()
      |> LibPE.encode()

    File.write!("test/hello-out.exe", raw)
  end

  # defp tip(rsrc) do
  #   clean_data(hd(rsrc.entries))
  # end

  defp test_files() do
    ["test/mt.exe", "test/dialyzer.exe"]
  end

  defp clean_data(map) when is_struct(map) do
    clean_data(Map.from_struct(map))
  end

  defp clean_data(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, ret ->
      value =
        cond do
          key == :raw_data -> :crypto.hash(:sha, value)
          key == :virtual_data -> :crypto.hash(:sha, value)
          key == :data_rva -> :cleaned
          is_map(value) -> clean_data(value)
          is_list(value) -> Enum.map(value, fn x -> clean_data(x) end)
          true -> value
        end

      Map.put(ret, key, value)
    end)
  end

  defp clean_data(other), do: other
end

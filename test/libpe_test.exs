defmodule LibPETest do
  use ExUnit.Case
  doctest LibPE

  test "test open file" do
    for filename <- ["test/dialyzer.exe", "test/mt.exe"] do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      assert raw == LibPE.encode(pe)
      assert pe.coff_header.checksum == LibPE.update_checksum(pe).coff_header.checksum
    end
  end

  test "test update file" do
    for filename <- ["test/dialyzer.exe", "test/mt.exe"] do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      assert clean_data(pe) == clean_data(LibPE.update_layout(pe))
    end
  end

  test "test parse resources" do
    for filename <- ["test/mt.exe", "test/dialyzer.exe"] do
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

  # defp tip(rsrc) do
  #   clean_data(hd(rsrc.entries))
  # end

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

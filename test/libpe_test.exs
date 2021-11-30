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

      assert pe == LibPE.update_layout(pe)
    end
  end

  test "test parse resources" do
    for filename <- ["test/mt.exe"] do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      resources = Enum.find(pe.coff_sections, fn sec -> sec.name == ".rsrc" end)

      rsrc = LibPE.ResourceDirectoryTable.parse(resources.virtual_data, resources.virtual_address)

      LibPE.ResourceDirectoryTable.dump(rsrc)

      resources2 = LibPE.ResourceDirectoryTable.encode(rsrc, resources.virtual_address)
      rsrc2 = LibPE.ResourceDirectoryTable.parse(resources2, resources.virtual_address)

      LibPE.ResourceDirectoryTable.dump(rsrc2)

      assert byte_size(resources.virtual_data) == byte_size(resources2)
      # assert resources.virtual_data == resources2
      assert rsrc == rsrc2
    end
  end
end

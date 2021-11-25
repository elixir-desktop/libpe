defmodule LibPETest do
  use ExUnit.Case
  doctest LibPE

  test "test open file" do
    for filename <- ["test/dialyzer.exe", "test/mt.exe"] do
      raw = File.read!(filename)
      {:ok, pe} = LibPE.parse_string(raw)

      IO.inspect(pe.coff_header)

      for section <- pe.coff_sections do
        IO.puts(section.name)
      end

      assert raw == LibPE.encode(pe)
      assert pe.coff_header.checksum == LibPE.update_checksum(pe).coff_header.checksum
    end
  end
end

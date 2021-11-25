defmodule LibPETest do
  use ExUnit.Case
  doctest LibPE

  test "test open file" do
    raw = File.read!("test/dialyzer.exe")
    {:ok, file} = LibPE.parse_string(raw)

    IO.inspect(file.coff_header)

    for section <- file.coff_sections do
      IO.puts(section.name)
    end

    assert raw == LibPE.encode(file)
  end
end

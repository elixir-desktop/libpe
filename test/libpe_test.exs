defmodule LibPETest do
  use ExUnit.Case
  doctest LibPE

  test "test open file" do
    {:ok, file} = LibPE.parse_file("test/dialyzer.exe")

    IO.inspect(file.coff_header)
    for section <- file.coff_sections do
      IO.puts(section.name)
    end
  end
end

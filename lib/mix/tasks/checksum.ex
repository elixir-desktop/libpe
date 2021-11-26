defmodule Mix.Tasks.Checksum do
  use Mix.Task

  @shortdoc "Checks the PE checksum of the provided file."
  def run([filename]) do
    {:ok, pe} = LibPE.parse_file(filename)

    checksum = pe.coff_header.checksum
    IO.puts("Current checksum is #{checksum}")
    pe2 = LibPE.update_checksum(pe)
    checksum2 = pe2.coff_header.checksum
    IO.puts("Calculated checksum is #{checksum2}")

    if checksum == checksum2 do
      IO.puts("CORRECT!")
    else
      IO.puts("WRONG!")
    end
  end
end

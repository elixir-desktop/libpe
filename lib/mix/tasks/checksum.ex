defmodule Mix.Tasks.Pe.Checksum do
  @moduledoc """
    SYNTAX: mix pe.checksum <filename> (<filename>...)

    pe.checksum checks the PE-checksum of the given pe files.
  """
  use Mix.Task

  @doc false
  def run([]) do
    IO.puts(@moduldoc)
    System.halt()
  end

  def run(filenames) do
    Enum.each(filenames, fn filename ->
      {:ok, pe} = LibPE.parse_file(filename)

      checksum = pe.coff_header.checksum
      pe2 = LibPE.update_checksum(pe)
      checksum2 = pe2.coff_header.checksum

      ret =
        if checksum == checksum2 do
          "CORRECT!"
        else
          "WRONG!"
        end

      name = String.pad_trailing(Path.basename(filename), 20)
      checksum = String.pad_leading("#{checksum}", 8)
      checksum2 = String.pad_leading("#{checksum2}", 8)

      IO.puts("#{name} checksum: #{checksum}, should: #{checksum2} ==> #{ret}")
    end)
  end
end

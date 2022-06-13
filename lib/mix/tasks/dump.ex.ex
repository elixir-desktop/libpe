defmodule Mix.Tasks.Pe.Dump do
  @moduledoc """
    SYNTAX: mix pe.dump (--raw) (--values) <filename> (<filename>...)

    pe.dump dumps the contents of a PE file.
  """
  use Mix.Task

  @doc false
  def run([]) do
    show_help()
  end

  def run(args) do
    %{files: files, raw: raw, values: values} =
      process_args(%{files: [], raw: false, values: false}, args)

    opts = [values: values]

    Enum.each(files, fn filename ->
      {:ok, pe} = LibPE.parse_file(filename)

      title = "Dumping file: #{Path.basename(filename)}"
      IO.puts(title)
      IO.puts(String.pad_trailing("", String.length(title), "="))

      if raw do
        IO.inspect(pe)
      else
        LibPE.get_resources(pe)
        |> LibPE.ResourceTable.dump(opts)
      end

      IO.puts("")
    end)
  end

  defp show_help() do
    IO.puts(@moduledoc)
    System.halt()
  end

  defp process_args(opts, []) do
    opts
  end

  defp process_args(opts, ["--values" | rest]) do
    %{opts | values: true}
    |> process_args(rest)
  end

  defp process_args(opts, ["--raw" | rest]) do
    %{opts | raw: true}
    |> process_args(rest)
  end

  defp process_args(_opts, ["--help" | _rest]), do: show_help()
  defp process_args(_opts, ["-h" | _rest]), do: show_help()

  defp process_args(opts, [arg | rest]) do
    if String.starts_with?(arg, "-") do
      raise("Unknown option string '#{arg}'")
    end

    %{opts | files: [arg | opts.files]}
    |> process_args(rest)
  end
end

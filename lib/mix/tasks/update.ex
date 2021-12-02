defmodule Mix.Tasks.Pe.Update do
  use Mix.Task

  def run([]) do
    show_help()
  end

  def run(args) do
    %{files: files, resources: resources} = process_args(%{resources: [], files: []}, args)

    Enum.each(files, fn filename ->
      {:ok, pe} = LibPE.parse_file(filename)

      IO.puts("Updating file #{filename}")

      raw =
        update_resources(pe, resources)
        |> LibPE.update_layout()
        |> LibPE.update_checksum()
        |> LibPE.encode()

      File.write!(filename, raw)
    end)
  end

  defp show_help() do
    IO.puts("""
      SYNTAX: mix pe.update (options) <filename>

      pe.update updates the PE-checksum of the given pe file and
      additionally can add resources to it if needed.

      Options are:

          -h | -help                        This help
          --set-icon <filename>             Embeds a given side-by-side manifest
          --set-manifest <filename>         Embeds a given application icon
          --set-resource <type> <filename>  Embeds any resources type
    """)

    System.halt()
  end

  defp update_resources(pe, []), do: pe

  defp update_resources(pe, updates) do
    resource_table = LibPE.get_resources(pe)

    resource_table =
      Enum.reduce(updates, resource_table, fn {type, data}, resource_table ->
        LibPE.ResourceTable.set_resource(resource_table, type, data)
      end)

    LibPE.set_resources(pe, resource_table)
  end

  defp process_args(opts, []) do
    opts
  end

  defp process_args(opts, ["--set-manifest", filename | rest]) do
    case File.read(filename) do
      {:ok, data} ->
        add_resource(opts, "RT_MANIFEST", data)
        |> process_args(rest)

      error ->
        raise "Failed to read manifest file #{filename}: #{inspect(error)}"
    end
    |> process_args(rest)
  end

  defp process_args(opts, ["--set-icon", filename | rest]) do
    case File.read(filename) do
      {:ok, data} ->
        add_resource(opts, "RT_ICON", data)
        |> process_args(rest)

      error ->
        raise "Failed to read icon file #{filename}: #{inspect(error)}"
    end
  end

  defp process_args(opts, ["--set-resource", name, filename | rest]) do
    data =
      case File.read(filename) do
        {:ok, data} -> data
        error -> raise "Failed to read resource file #{filename}: #{inspect(error)}"
      end

    add_resource(opts, name, data)
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

  defp add_resource(opts, name, data) do
    if not is_integer(name) and not LibPE.Flags.is_name(LibPE.ResourceTypes, name) do
      raise """
        The specified resource name #{name} is not a known name. Known resource names
        are only:

        #{inspect(LibPE.Flags.names(LibPE.ResourceTypes))}
      """
    end

    name = LibPE.ResourceTypes.encode(name)
    %{opts | resources: [{name, data} | opts.resources]}
  end
end

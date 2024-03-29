defmodule Mix.Tasks.Pe.Update do
  @moduledoc """
    SYNTAX: mix pe.update (options) <filename>

    pe.update updates the PE-checksum of the given pe file and
    additionally can add resources to it if needed.

    Options are:

        -h | -help                        This help
        --set-subsystem <subsystemcode>   Update the PE files subsytem type
        --set-icon <filename>             Embeds a given application icon
        --get-icon <filename>             Extracts an embedded icon and stores it to the filename
        --set-manifest <filename>         Embeds a given side-by-side manifest
        --set-info <info_type> <value>    Embeds the given version information
        --set-resource <type> <filename>  Embeds any resources type
        --del-resource <type>             Remove any resources type

    Known info types are:

      "Comments", "CompanyName", "FileDescription", "FileVersion", "InternalName",
      "LegalCopyright", "LegalTrademarks", "OriginalFilename", "PrivateBuild",
      "ProductName", "ProductVersion", "SpecialBuild"

    Known resources types are:

      "RT_ACCELERATOR", "RT_ANICURSOR", "RT_ANIICON", "RT_BITMAP", "RT_CURSOR",
      "RT_DIALOG", "RT_DLGINCLUDE", "RT_FONT", "RT_FONTDIR", "RT_GROUP_CURSOR",
      "RT_GROUP_ICON", "RT_HTML", "RT_ICON", "RT_MANIFEST", "RT_MENU",
      "RT_MESSAGETABLE", "RT_PLUGPLAY", "RT_RCDATA", "RT_STRING", "RT_VERSION",
      "RT_VXD"
  """
  use Mix.Task

  @doc false
  def run([]) do
    show_help()
  end

  def run(args) do
    %{files: files, resources: resources, resource_updates: resource_updates, updates: updates} =
      process_args(%{resources: [], resource_updates: %{}, files: [], updates: []}, args)

    if files == [] do
      error("No files given")
    end

    Enum.each(files, fn filename ->
      {:ok, pe} = LibPE.parse_file(filename)

      IO.puts("Updating file #{filename}")

      raw =
        update_resources(pe, resources, resource_updates)
        |> update_other(updates)
        |> LibPE.update_checksum()
        |> LibPE.encode()

      File.write!(filename, raw)
    end)
  end

  def error(msg) do
    Mix.Shell.IO.error(msg)
    # Mix.Shell.IO.info(@moduledoc)
    System.halt(1)
  end

  defp show_help() do
    Mix.Shell.IO.info(@moduledoc)
    System.halt()
  end

  defp update_other(pe, updates) do
    Enum.reduce(updates, pe, fn update, pe ->
      update.(pe)
    end)
  end

  defp update_resources(pe, replacements, resource_updates) do
    if replacements == [] and map_size(resource_updates) == 0 do
      pe
    else
      do_update_resources(pe, replacements, resource_updates)
    end
  end

  defp do_update_resources(pe, replacements, resource_updates) do
    resource_table = LibPE.get_resources(pe)

    resource_table =
      Enum.reduce(replacements, resource_table, fn {type, data}, resource_table ->
        LibPE.ResourceTable.set_resource(resource_table, type, data)
      end)

    resource_table =
      Enum.reduce(resource_updates, resource_table, fn {type, funs}, resource_table ->
        resource = LibPE.ResourceTable.get_resource(resource_table, type)

        new_resource =
          Enum.reduce(funs, resource, fn fun, resource ->
            fun.(resource)
          end)

        if new_resource != resource do
          LibPE.ResourceTable.set_resource(resource_table, type, new_resource)
        else
          resource_table
        end
      end)

    LibPE.set_resources(pe, resource_table)
    |> LibPE.update_layout()
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
        error("Failed to read manifest file #{filename}: #{inspect(error)}")
    end
    |> process_args(rest)
  end

  defp process_args(opts, ["--set-subsystem", value | rest]) do
    LibPE.WindowsSubsystem.flags()
    |> Enum.find(fn {name, num, _desc} -> value == name or value == "#{num}" end)
    |> case do
      nil ->
        error(
          "Failed find subsystem value '#{value}'. Valid values are: #{inspect(LibPE.WindowsSubsystem.flags())}"
        )

      sub ->
        add_update(opts, fn pe -> %{pe | coff_header: %{pe.coff_header | subsystem: sub}} end)
        |> process_args(rest)
    end
  end

  defp process_args(opts, ["--set-icon", filename | rest]) do
    case File.read(filename) do
      {:ok, data} ->
        opts
        |> add_resource("RT_ICON", data)
        |> drop_resource("RT_GROUP_ICON")
        |> process_args(rest)

      error ->
        error("Failed to read icon file #{filename}: #{inspect(error)}")
    end
  end

  defp process_args(opts, ["--get-icon", filename | rest]) do
    if File.exists?(filename) do
      error("The output file already exists: #{filename}")
    end

    update_resource(opts, "RT_ICON", fn icon ->
      if icon == nil do
        Mix.Shell.IO.error("No icon found in the file")
      else
        File.write!(filename, icon.entry.data)
      end

      icon
    end)
    |> process_args(rest)
  end

  defp process_args(opts, ["--set-resource", name, filename | rest]) do
    data =
      case File.read(filename) do
        {:ok, data} -> data
        error -> error("Failed to read resource file #{filename}: #{inspect(error)}")
      end

    add_resource(opts, name, data)
    |> process_args(rest)
  end

  defp process_args(opts, ["--del-resource", name | rest]) do
    add_resource(opts, name, nil)
    |> process_args(rest)
  end

  defp process_args(opts, ["--set-info", name, value | rest]) do
    update = fn version ->
      page = LibPE.Codepage.encode(0)
      lang = LibPE.Language.encode(1033)

      version =
        version ||
          %LibPE.ResourceTable.DirEntry{
            name: lang,
            entry: %LibPE.ResourceTable.DataBlob{
              codepage: page,
              data: LibPE.VersionInfo.encode(LibPE.VersionInfo.new())
            }
          }

      data =
        LibPE.VersionInfo.decode(version.entry.data)
        |> Map.update!(:strings, fn strings -> List.keystore(strings, name, 0, {name, value}) end)
        |> LibPE.VersionInfo.encode()

      %{version | entry: %{version.entry | data: data}}
    end

    update_resource(opts, "RT_VERSION", update)
    |> process_args(rest)
  end

  defp process_args(_opts, ["--help" | _rest]), do: show_help()
  defp process_args(_opts, ["-h" | _rest]), do: show_help()

  defp process_args(opts, [arg | rest]) do
    if String.starts_with?(arg, "-") do
      error("Unknown option string '#{arg}'")
    end

    %{opts | files: [arg | opts.files]}
    |> process_args(rest)
  end

  defp drop_resource(opts, name) do
    add_resource(opts, name, nil)
  end

  defp add_update(opts, update_fun) do
    %{opts | updates: [update_fun | opts.updates]}
  end

  defp add_resource(opts, name, data) do
    if not is_integer(name) and not LibPE.Flags.is_name(LibPE.ResourceTypes, name) do
      error("""
        The specified resource name #{name} is not a known name. Known resource names
        are only:

        #{inspect(LibPE.Flags.names(LibPE.ResourceTypes))}
      """)
    end

    name = LibPE.ResourceTypes.encode(name)
    %{opts | resources: [{name, data} | opts.resources]}
  end

  defp update_resource(opts, name, fun) do
    if not is_integer(name) and not LibPE.Flags.is_name(LibPE.ResourceTypes, name) do
      error("""
        The specified resource name #{name} is not a known name. Known resource names
        are only:

        #{inspect(LibPE.Flags.names(LibPE.ResourceTypes))}
      """)
    end

    name = LibPE.ResourceTypes.encode(name)

    %{
      opts
      | resource_updates:
          Map.update(opts.resource_updates, name, [fun], fn rest -> rest ++ [fun] end)
    }
  end
end

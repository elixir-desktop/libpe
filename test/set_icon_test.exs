defmodule LibPE.SetIconTest do
  use ExUnit.Case, async: false

  alias LibPE.ResourceTable
  alias LibPE.ResourceTable.{DataBlob, DirEntry}

  @logo "test/fixtures/logo.ico"
  @base "test/fixtures/base/hello.exe"
  @golden "test/fixtures/golden/hello_rcedit.exe"
  @dump "test/fixtures/dumps/hello_rcedit.term"

  setup_all do
    ico = File.read!(@logo)
    golden_dump = :erlang.binary_to_term(File.read!(@dump))
    %{ico: ico, golden_dump: golden_dump}
  end

  test "libpe Icon.set matches rcedit /I resource structure", %{ico: ico, golden_dump: golden} do
    {:ok, pe} = LibPE.parse_file(@base)
    resources = LibPE.get_resources(pe) |> LibPE.Icon.set(ico)
    pe = LibPE.set_resources(pe, resources) |> LibPE.update_checksum()

    assert_icon_structure(LibPE.get_resources(pe), golden)

    # RT_ICON payloads must not be a raw ICO (no ICONDIR magic)
    icons = icon_payloads(LibPE.get_resources(pe))
    refute Enum.any?(icons, fn data -> binary_part(data, 0, 4) == <<0, 0, 1, 0>> end)

    # PE checksum field matches computed
    assert pe.coff_header.checksum == LibPE.update_checksum(pe).coff_header.checksum

    # encode/parse stays structurally stable for icons
    raw = LibPE.encode(pe)
    {:ok, pe2} = LibPE.parse_string(raw)
    assert_icon_structure(LibPE.get_resources(pe2), golden)
  end

  test "rcedit golden has GROUP_ICON and ICON payloads", %{golden_dump: golden} do
    {:ok, pe} = LibPE.parse_file(@golden)
    assert_icon_structure(LibPE.get_resources(pe), golden)
  end

  test "Icon.get rebuilds ico from resources", %{ico: ico} do
    {:ok, pe} = LibPE.parse_file(@base)
    resources = LibPE.get_resources(pe) |> LibPE.Icon.set(ico)
    out = LibPE.Icon.get(resources)
    assert is_binary(out)
    images = LibPE.ICO.parse!(out)
    assert length(images) == 1
    assert hd(images).payload == hd(LibPE.ICO.parse!(ico)).payload
  end

  test "mix pe.update --set-icon writes GROUP and ICON", %{ico: ico} do
    tmp = Path.join(System.tmp_dir!(), "libpe_set_icon_#{System.unique_integer([:positive])}.exe")
    File.cp!(@base, tmp)

    on_exit(fn -> File.rm(tmp) end)

    :ok = Mix.Tasks.Pe.Update.run(["--set-icon", @logo, tmp])

    {:ok, pe} = LibPE.parse_file(tmp)
    rsrc = LibPE.get_resources(pe)
    assert find_type(rsrc, "RT_GROUP_ICON")
    assert find_type(rsrc, "RT_ICON")
    [payload] = icon_payloads(rsrc)
    assert payload == hd(LibPE.ICO.parse!(ico)).payload
    assert pe.coff_header.checksum == LibPE.update_checksum(pe).coff_header.checksum
  end

  defp assert_icon_structure(rsrc, golden) do
    icons = icon_entries(rsrc)
    assert length(icons) == length(golden.icons)

    Enum.zip(icons, golden.icons)
    |> Enum.each(fn {got, want} ->
      assert got.name == want.name
      assert got.data == want.data
    end)

    group = group_entry(rsrc)
    assert group != nil
    assert group.data == golden.group.data

    <<0::little-16, 1::little-16, count::little-16, _::binary>> = group.data
    assert count == length(golden.icons)
  end

  defp icon_entries(rsrc) do
    case find_type(rsrc, "RT_ICON") do
      nil ->
        []

      %DirEntry{entry: %ResourceTable{entries: names}} ->
        Enum.map(names, fn %DirEntry{name: name, entry: %ResourceTable{entries: langs}} ->
          %DirEntry{entry: %DataBlob{data: data}} = hd(langs)
          %{name: name, data: data}
        end)
        |> Enum.sort_by(& &1.name)
    end
  end

  defp icon_payloads(rsrc), do: Enum.map(icon_entries(rsrc), & &1.data)

  defp group_entry(rsrc) do
    case find_type(rsrc, "RT_GROUP_ICON") do
      %DirEntry{
        entry: %ResourceTable{entries: [%DirEntry{entry: %ResourceTable{entries: langs}} | _]}
      } ->
        %DirEntry{entry: %DataBlob{data: data}} = hd(langs)
        %{data: data}

      _ ->
        nil
    end
  end

  defp find_type(%ResourceTable{entries: entries}, type_name) do
    type = LibPE.ResourceTypes.encode(type_name)
    Enum.find(entries, fn %DirEntry{name: n} -> n == type end)
  end
end

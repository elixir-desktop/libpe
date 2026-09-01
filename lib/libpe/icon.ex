defmodule LibPE.Icon do
  @moduledoc """
  Set/get the default PE icon (`RT_GROUP_ICON` + `RT_ICON`) from a `.ico` file.

  Matches the semantics of WinRun4J `RCEDIT /I`: replace the default icon group
  (name `1`) and its referenced `RT_ICON` images.
  """

  alias LibPE.ResourceTable
  alias LibPE.ResourceTable.{DataBlob, DirEntry}

  # rcedit /I uses lang 1033 for RT_ICON and lang 0 for RT_GROUP_ICON
  @icon_lang 1033
  @group_lang 0
  @group_name 1

  @doc """
  Replace the default icon resources in a resource table with images from an ICO binary.
  """
  def set(%ResourceTable{} = table, ico_binary) when is_binary(ico_binary) do
    images = LibPE.ICO.parse!(ico_binary)

    table
    |> clear_default_icons()
    |> put_icon_images(images)
    |> put_group_icon(images)
  end

  @doc """
  Rebuild a `.ico` binary from the default `RT_GROUP_ICON` + `RT_ICON` resources.
  Returns `nil` when no group icon is present.
  """
  def get(%ResourceTable{} = table) do
    case find_type(table, "RT_GROUP_ICON") do
      nil ->
        nil

      %DirEntry{entry: %ResourceTable{entries: names}} ->
        case Enum.find(names, fn %DirEntry{name: n} -> n == @group_name end) do
          nil ->
            nil

          %DirEntry{entry: %ResourceTable{entries: langs}} ->
            %DirEntry{entry: %DataBlob{data: group}} = hd(langs)
            images = images_from_group(table, group)
            LibPE.ICO.encode(images)
        end
    end
  end

  defp clear_default_icons(table) do
    # Drop entire RT_GROUP_ICON and RT_ICON types (default-icon replace, like /I)
    table
    |> ResourceTable.set_resource("RT_GROUP_ICON", nil)
    |> ResourceTable.set_resource("RT_ICON", nil)
  end

  defp put_icon_images(table, images) do
    icon_names =
      images
      |> Enum.with_index(1)
      |> Enum.map(fn {img, id} ->
        %DirEntry{
          name: id,
          entry: %ResourceTable{
            entries: [
              %DirEntry{
                name: @icon_lang,
                entry: %DataBlob{codepage: 0, data: img.payload}
              }
            ]
          }
        }
      end)

    put_type(table, "RT_ICON", icon_names)
  end

  defp put_group_icon(table, images) do
    group = encode_group_icon(images)

    put_type(table, "RT_GROUP_ICON", [
      %DirEntry{
        name: @group_name,
        entry: %ResourceTable{
          entries: [
            %DirEntry{
              name: @group_lang,
              entry: %DataBlob{codepage: 0, data: group}
            }
          ]
        }
      }
    ])
  end

  defp encode_group_icon(images) do
    count = length(images)
    header = <<0::little-16, 1::little-16, count::little-16>>

    entries =
      images
      |> Enum.with_index(1)
      |> Enum.map(fn {img, id} ->
        w = if img.width >= 256, do: 0, else: img.width
        h = if img.height >= 256, do: 0, else: img.height
        size = byte_size(img.payload)

        <<w, h, img.color_count, 0, img.planes::little-16, img.bit_count::little-16,
          size::little-32, id::little-16>>
      end)
      |> IO.iodata_to_binary()

    header <> entries
  end

  defp images_from_group(table, <<0::little-16, 1::little-16, count::little-16, rest::binary>>) do
    icon_type = find_type(table, "RT_ICON")

    Enum.map(1..count, fn i ->
      offset = (i - 1) * 14

      <<w, h, cc, _res, planes::little-16, bit_count::little-16, _bytes::little-32,
        id::little-16>> =
        binary_part(rest, offset, 14)

      payload = fetch_icon_payload!(icon_type, id)

      %{
        width: if(w == 0, do: 256, else: w),
        height: if(h == 0, do: 256, else: h),
        color_count: cc,
        planes: planes,
        bit_count: bit_count,
        payload: payload
      }
    end)
  end

  defp fetch_icon_payload!(nil, id), do: raise("RT_ICON missing for id #{id}")

  defp fetch_icon_payload!(%DirEntry{entry: %ResourceTable{entries: names}}, id) do
    case Enum.find(names, fn %DirEntry{name: n} -> n == id end) do
      %DirEntry{entry: %ResourceTable{entries: [%DirEntry{entry: %DataBlob{data: data}} | _]}} ->
        data

      _ ->
        raise "RT_ICON id #{id} not found"
    end
  end

  defp find_type(%ResourceTable{entries: entries}, type_name) do
    type = LibPE.ResourceTypes.encode(type_name)
    Enum.find(entries, fn %DirEntry{name: n} -> n == type end)
  end

  defp put_type(%ResourceTable{entries: entries} = table, type_name, name_entries) do
    type = LibPE.ResourceTypes.encode(type_name)
    entry = %DirEntry{name: type, entry: %ResourceTable{entries: name_entries}}
    idx = Enum.find_index(entries, fn %DirEntry{name: n} -> n == type end)

    entries =
      if idx == nil do
        entries ++ [entry]
      else
        List.replace_at(entries, idx, entry)
      end

    # Re-sort via set_resource delete+... use ResourceTable sorted by re-encoding path
    # sorted_entries is private; approximate by putting integers after — encode sorts anyway
    %ResourceTable{table | entries: entries}
  end
end

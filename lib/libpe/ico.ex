defmodule LibPE.ICO do
  @moduledoc """
  Parser/encoder for Windows `.ico` files (ICONDIR).

  Image payloads are returned as stored in the ICO (DIB without BITMAPFILEHEADER,
  or PNG). Those payloads are what PE `RT_ICON` resources expect.
  """

  defstruct images: []

  @type image :: %{
          width: non_neg_integer(),
          height: non_neg_integer(),
          color_count: non_neg_integer(),
          planes: non_neg_integer(),
          bit_count: non_neg_integer(),
          payload: binary()
        }

  @doc """
  Parse an `.ico` binary into a list of images.
  """
  def parse!(<<0::little-16, 1::little-16, count::little-16, rest::binary>> = full)
      when count > 0 do
    {entries, _} = parse_entries(count, rest, [])

    Enum.map(entries, fn entry ->
      payload = binary_part(full, entry.image_offset, entry.bytes_in_res)

      %{
        width: normalize_dim(entry.width),
        height: normalize_dim(entry.height),
        color_count: entry.color_count,
        planes: entry.planes,
        bit_count: entry.bit_count,
        payload: payload
      }
    end)
  end

  def parse!(<<0::little-16, 1::little-16, 0::little-16, _::binary>>) do
    raise ArgumentError, "ICO contains no images"
  end

  def parse!(_) do
    raise ArgumentError, "not a Windows ICO file"
  end

  def parse(bin) do
    {:ok, parse!(bin)}
  rescue
    e in [ArgumentError, MatchError, FunctionClauseError] ->
      {:error, Exception.message(e)}
  end

  @doc """
  Encode images back to a `.ico` binary.
  """
  def encode(images) when is_list(images) and images != [] do
    count = length(images)
    header = <<0::little-16, 1::little-16, count::little-16>>
    # Directory is 6 + 16*count bytes; payloads follow
    dir_size = 6 + 16 * count

    {entries, payloads, _offset} =
      Enum.reduce(images, {<<>>, <<>>, dir_size}, fn img, {ents, pays, offset} ->
        w = encode_dim(img.width)
        h = encode_dim(img.height)
        size = byte_size(img.payload)

        entry =
          <<w, h, img.color_count, 0, img.planes::little-16, img.bit_count::little-16,
            size::little-32, offset::little-32>>

        {ents <> entry, pays <> img.payload, offset + size}
      end)

    header <> entries <> payloads
  end

  defp parse_entries(0, rest, acc), do: {Enum.reverse(acc), rest}

  defp parse_entries(
         n,
         <<width, height, color_count, _reserved, planes::little-16, bit_count::little-16,
           bytes_in_res::little-32, image_offset::little-32, rest::binary>>,
         acc
       ) do
    entry = %{
      width: width,
      height: height,
      color_count: color_count,
      planes: planes,
      bit_count: bit_count,
      bytes_in_res: bytes_in_res,
      image_offset: image_offset
    }

    parse_entries(n - 1, rest, [entry | acc])
  end

  defp normalize_dim(0), do: 256
  defp normalize_dim(n), do: n

  defp encode_dim(256), do: 0
  defp encode_dim(n) when n >= 0 and n < 256, do: n
end

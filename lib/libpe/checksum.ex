defmodule LibPE.Checksum do
  # from https://bytepointer.com/resources/microsoft_pe_checksum_algo_distilled.htm David N. Cutler 1993
  use Bitwise
  @max_word 0xFFFF
  @max_long 0xFFFFFFFF
  @max_long_long 0xFFFFFFFFFFFFFFFF

  # prepare alignment, remove checksum, add length
  def checksum(binary, checksum_offset) do
    <<pre_amble::binary-size(checksum_offset), _checksum::little-size(16), rest::binary>> = binary

    new_binary = pre_amble <> rest
    new_binary = String.pad_trailing(new_binary, ceil(byte_size(new_binary) / 2) * 2, <<0>>)

    rem(chk_sum(new_binary) + (byte_size(binary) &&& @max_long), @max_long_long)
  end

  def chk_sum(partial_sum \\ 0, source) do
    partial_sum =
      for(<<source_word::little-size(16) <- source>>, do: source_word)
      |> Enum.reduce(partial_sum, fn source_word, partial_sum ->
        partial_sum = partial_sum + source_word
        partial_sum = (partial_sum >>> 16 &&& @max_long) + (partial_sum &&& @max_word)
        partial_sum
      end)

    (partial_sum >>> 16) + partial_sum &&& @max_word
  end
end

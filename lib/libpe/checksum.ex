defmodule LibPE.Checksum do
  @moduledoc """
    Elixir implementation of the PE checksum algorithm by David N. Cutler 1993
    from https://bytepointer.com/resources/microsoft_pe_checksum_algo_distilled.htm
  """
  use Bitwise
  @max_word 0xFFFF
  @max_long 0xFFFFFFFF
  @max_long_long 0xFFFFFFFFFFFFFFFF

  @doc """
    binary_size is provided so embedded `checksum` values can be removed
    before running and added afterwards again.
  """
  def checksum(binary, binary_size) do
    # ensure alignment
    new_binary = LibPE.binary_pad_trailing(binary, ceil(byte_size(binary) / 2) * 2)
    rem(do_checksum(new_binary) + (binary_size &&& @max_long), @max_long_long)
  end

  defp do_checksum(partial_sum \\ 0, source) do
    partial_sum =
      for(<<source_word::little-size(16) <- source>>, do: source_word)
      |> Enum.reduce(partial_sum, fn source_word, partial_sum ->
        partial_sum = rem(partial_sum + source_word, @max_long)
        partial_sum = (partial_sum >>> 16) + (partial_sum &&& @max_word)
        rem(partial_sum, @max_long)
      end)

    rem((partial_sum >>> 16) + partial_sum, @max_long) &&& @max_word
  end
end

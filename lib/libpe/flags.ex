defmodule LibPE.Flags do
  use Bitwise

  def decode(module, id) do
    Enum.find(module.flags(), id, fn {_, value, _} -> value == id end)
  end

  def encode(module, value) do
    case value do
      value when is_integer(value) ->
        value

      {_, value, _} ->
        value

      name when is_binary(value) ->
        {_, value, _} = Enum.find(module.flags(), fn {ename, _, _} -> name == ename end)
        value
    end
  end

  def decode_many(module, numeric_flags) do
    Enum.reduce(module.flags(), [], fn char, acc ->
      {_, id, _} = char

      if (numeric_flags &&& id) == 0 do
        acc
      else
        acc ++ [char]
      end
    end)
  end

  def encode_many(_module, numeric_flag) when is_integer(numeric_flag), do: numeric_flag

  def encode_many(module, flags) when is_list(flags) do
    Enum.reduce(flags, 0, fn flag, ret ->
      num =
        case flag do
          num when is_integer(flag) ->
            num

          {_, num, _} ->
            num

          name when is_binary(name) ->
            {_, num, _} = Enum.find(module.flags(), fn {ename, _, _} -> name == ename end)
            num
        end

      ret ||| num
    end)
  end
end

defmodule LibPE.Flags do
  @moduledoc false
  import Bitwise

  defmacro __using__(opts) do
    if :many in opts do
      quote do
        @moduledoc false
        alias LibPE.Flags
        def decode(flags), do: Flags.decode_many(__MODULE__, flags)
        def encode(flags), do: Flags.encode_many(__MODULE__, flags)
      end
    else
      quote do
        @moduledoc false
        alias LibPE.Flags
        def decode(flags), do: Flags.decode(__MODULE__, flags)
        def encode(flags), do: Flags.encode(__MODULE__, flags)
      end
    end
  end

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
        case Enum.find(module.flags(), fn {ename, _, _} -> name == ename end) do
          {_, value, _} -> value
          nil -> raise "Unknown #{module} flag: #{inspect(name)}"
        end
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

  def is_name(module, name) do
    name in names(module)
  end

  def names(module) do
    Enum.map(module.flags(), fn {name, _, _} -> name end)
  end
end

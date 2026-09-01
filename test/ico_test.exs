defmodule LibPE.ICOTest do
  use ExUnit.Case, async: true

  @logo "test/fixtures/logo.ico"

  test "parses logo.ico" do
    images = LibPE.ICO.parse!(File.read!(@logo))
    assert length(images) == 1
    [img] = images
    assert img.width == 128
    assert img.height == 53
    assert img.bit_count == 32
    assert byte_size(img.payload) == 28024
    # BITMAPINFOHEADER biSize = 40
    assert binary_part(img.payload, 0, 4) == <<40, 0, 0, 0>>
  end

  test "rejects non-ico" do
    assert {:error, _} = LibPE.ICO.parse(<<"MZ", 0, 1, 2, 3>>)
    assert_raise ArgumentError, fn -> LibPE.ICO.parse!(<<"not an ico">>) end
  end

  test "encode roundtrip preserves payloads" do
    images = LibPE.ICO.parse!(File.read!(@logo))
    again = LibPE.ICO.parse!(LibPE.ICO.encode(images))
    assert Enum.map(again, & &1.payload) == Enum.map(images, & &1.payload)

    assert Enum.map(again, &{&1.width, &1.height, &1.bit_count}) ==
             Enum.map(images, &{&1.width, &1.height, &1.bit_count})
  end
end

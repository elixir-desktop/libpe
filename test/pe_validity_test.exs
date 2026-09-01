defmodule LibPE.PeValidityTest do
  use ExUnit.Case, async: false

  @logo "test/fixtures/logo.ico"
  @base "test/fixtures/base/hello.exe"

  test "set-icon PE remains parseable and checksum-consistent" do
    tmp = Path.join(System.tmp_dir!(), "libpe_valid_#{System.unique_integer([:positive])}.exe")
    File.cp!(@base, tmp)
    on_exit(fn -> File.rm(tmp) end)

    :ok = Mix.Tasks.Pe.Update.run(["--set-icon", @logo, tmp])

    raw = File.read!(tmp)
    {:ok, pe} = LibPE.parse_string(raw)
    assert pe.coff_header.checksum == LibPE.update_checksum(pe).coff_header.checksum

    # Roundtrip encode does not blow up
    encoded = LibPE.encode(pe)
    assert {:ok, _} = LibPE.parse_string(encoded)

    # Has proper icon resources
    rsrc = LibPE.get_resources(pe)
    assert LibPE.Icon.get(rsrc)

    if match?({:win32, _}, :os.type()) do
      dumpbin =
        System.find_executable("dumpbin") ||
          case :filelib.wildcard(
                 ~c"C:/Program Files/Microsoft Visual Studio/*/*/VC/Tools/MSVC/*/bin/Hostx64/x64/dumpbin.exe"
               ) do
            [path | _] -> List.to_string(path)
            _ -> nil
          end

      if dumpbin do
        {out, _status} = System.cmd(dumpbin, ["/headers", tmp], stderr_to_stdout: true)
        assert out =~ "PE signature found"
        assert out =~ ~r/subsystem/i
      end
    end
  end
end

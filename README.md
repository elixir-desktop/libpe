# LibPE

[![Module Version](https://img.shields.io/hexpm/v/libpe.svg)](https://hex.pm/packages/libpe)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/libpe/)
[![Total Download](https://img.shields.io/hexpm/dt/libpe.svg)](https://hex.pm/packages/libpe)
[![License](https://img.shields.io/hexpm/l/libpe.svg)](https://github.com/elixir-desktop/libpe/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/elixir-desktop/libpe.svg)](https://github.com/elixir-desktop/libpe/commits/master)

Library and mix tasks to read and update Windows PE file resources. Based on https://docs.microsoft.com/en-us/windows/win32/debug/pe-format

*Only tested/needed with .exe files so far.*

## Example Usage

To check an existing PE file (.exe)

```bash
  mix pe.checksum <filename.exe>
```

To update the checksum:

```bash
  mix pe.update <filename.exe>
```

To list all resources in a file:

```bash
  mix pe.dump <filename.exe>
```

To set an icon resource (and update the checksum):

```bash
  mix pe.update --set-icon <icon.png> <filename.exe>
```



## Installation

To add LibPE to your build steps and make the tasks availabe add `libpe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libpe, "~> 1.0.0", only: :dev, runtime: false}
  ]
end
```


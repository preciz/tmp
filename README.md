# Tmp

![Actions Status](https://github.com/preciz/tmp/workflows/test/badge.svg)

Temporary directories that are monitored and automatically removed.

## Installation

The package can be installed by adding `tmp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tmp, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
iex> Tmp.dir(fn tmp_dir_path -> File.touch(Path.join(tmp_dir_path, "file_one")); 2 + 2 end)
4
```

Documentation can be found at [https://hexdocs.pm/tmp](https://hexdocs.pm/tmp).

## License

Tmp is [MIT licensed](LICENSE).

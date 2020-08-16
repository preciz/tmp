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

`Tmp.dir/2` accepts a function that will run in a new linked GenServer process.
The function will be called with the path of a new temporary directory.
If the function returns or the parent process exits the temporary directory is removed.

Options:
 - `:base_dir` defaults to `System.tmp_dir()`
 - `:dirname` defaults to a randomly generated uid
 - `:timeout` defaults to `:infinity`

```elixir
Tmp.dir(fn tmp_dir_path ->
  File.touch(Path.join(tmp_dir_path, "file_one"))
  # other important work

  2 + 2
end, dirname: "yolo")
# => 4
```

## Config

To configure the default base dir:
```
config :tmp, default_base_dir: "/tmp/my_dir"
```

## Docs

Documentation can be found at [https://hexdocs.pm/tmp](https://hexdocs.pm/tmp).

## License

Tmp is [MIT licensed](LICENSE).

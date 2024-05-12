# Tmp

[![test](https://github.com/preciz/tmp/actions/workflows/test.yml/badge.svg)](https://github.com/preciz/tmp/actions/workflows/test.yml)

Temporary directories that are monitored and automatically removed.

## Installation

The package can be installed by adding `tmp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tmp, "~> 0.2.0"}
  ]
end
```

## Usage

`Tmp.dir/2` accepts a function that will be called with the path of a new temporary directory.
If the function returns or the calling process exits the temporary directory is removed.

```elixir
Tmp.dir(fn tmp_dir_path ->
  # ... do work with tmp_dir_path
end)
```

Options:
 - `:prefix` (optional) prefix for the temporary directory, defaults to `nil`
 - `:base_dir` (optional) base directory of the temprorary directory, defaults to `System.tmp_dir()`
 - `:timeout` (optional) a timeout in milliseconds, defaults to `:infinity`

```elixir
Tmp.dir(fn tmp_dir_path ->
  File.touch(Path.join(tmp_dir_path, "file_one"))
  # ... other important work

  2 + 2
end, prefix: "yolo", base_dir: "/tmp/my_app")
# => 4
```

```elixir
Tmp.dir(fn tmp_dir_path ->
  case work(tmp_dir_path) do
    {:ok, result} ->
      {:ok, result}

    {:error, reason} ->
      # call `Tmp.keep()` to keep dir for debugging
      Tmp.keep()

      Logger.error("Error: #{inspect(reason)}, tmp dir: #{tmp_dir_path}")

      {:error, reason}
end)
```

## Config

(Optional) To configure the default base dir:
```
config :tmp, default_base_dir: "/tmp/my_dir"
```

## Docs

Documentation can be found at [https://hexdocs.pm/tmp](https://hexdocs.pm/tmp).

## License

Tmp is [MIT licensed](LICENSE).

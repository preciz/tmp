# Tmp

[![test](https://github.com/preciz/tmp/actions/workflows/test.yml/badge.svg)](https://github.com/preciz/tmp/actions/workflows/test.yml)

Temporary directories that are monitored and automatically removed.

## Installation

The package can be installed by adding `tmp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tmp, "~> 0.3.0"}
  ]
end
```

## Usage

`Tmp.dir/2` accepts a function that will be called with the path of a new temporary directory.
The temporary directory is automatically removed when the function returns or the calling process exits.

```elixir
Tmp.dir(fn tmp_dir_path ->
  # ... do work with tmp_dir_path
end)
```

### Options

- `:prefix` (optional) - Prefix for the temporary directory name, defaults to `nil`
- `:base_dir` (optional) - Base directory for the temporary directory, defaults to `System.tmp_dir()`
- `:timeout` (optional) - Timeout in milliseconds, defaults to `:infinity`

### Examples

Basic usage:

```elixir
Tmp.dir(fn tmp_dir_path ->
  File.touch(Path.join(tmp_dir_path, "file_one"))
  # ... other important work

  2 + 2
end, prefix: "my_app", base_dir: "/tmp/custom_base")
# => 4
```

Error handling:

```elixir
Tmp.dir(fn tmp_dir_path ->
  case work(tmp_dir_path) do
    {:ok, result} ->
      {:ok, result}

    {:error, reason} ->
      Logger.error("Error: #{inspect(reason)}, tmp dir: #{tmp_dir_path}")
      {:error, reason}
  end
end)
```

## Config

(Optional) To configure the default base directory:

```elixir
config :tmp, default_base_dir: "/tmp/my_custom_dir"
```

## Docs

Documentation can be found at [https://hexdocs.pm/tmp](https://hexdocs.pm/tmp).

## License

Tmp is [MIT licensed](LICENSE).

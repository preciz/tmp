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

Define your Tmp module:

```elixir
defmodule MyApp.Tmp do
  use Tmp
end

# Or with a custom base directory
defmodule MyApp.CustomTmp do
  use Tmp, base_dir: "/path/to/custom/base/dir"
end
```

Add it to your supervision tree:

```elixir
children = [
  {MyApp.Tmp, name: MyApp.Tmp}
]
```

Use it in your code:

```elixir
MyApp.Tmp.dir(fn tmp_dir_path ->
  file_path = Path.join(tmp_dir_path, "my_file")
  # do work with file_path...
  # then return a value
  {:ok, :work_done}
end)
```

### Options

When calling `MyApp.Tmp.dir/2`, you can pass the following options:

- `:prefix` (optional) - Prefix for the temporary directory name, defaults to `nil`
- `:base_dir` (optional) - Base directory for the temporary directory, defaults to `System.tmp_dir()` or the value set in `use Tmp`
- `:timeout` (optional) - Timeout in milliseconds, defaults to `:infinity`

### Examples

Basic usage:

```elixir
MyApp.Tmp.dir(fn tmp_dir_path ->
  File.touch(Path.join(tmp_dir_path, "file_one"))
  # ... other important work

  2 + 2
end, prefix: "my_app", base_dir: "/tmp/custom_base")
# => 4
```

Using a custom base directory:

```elixir
MyApp.CustomTmp.dir(fn tmp_dir_path ->
  # tmp_dir_path will be within "/path/to/custom/base/dir"
  File.touch(Path.join(tmp_dir_path, "file_in_custom_dir"))
  # ... other work
end)
```

Error handling:

```elixir
MyApp.Tmp.dir(fn tmp_dir_path ->
  case work(tmp_dir_path) do
    {:ok, result} ->
      {:ok, result}

    {:error, reason} ->
      Logger.error("Error: #{inspect(reason)}, tmp dir: #{tmp_dir_path}")
      {:error, reason}
  end
end)
```

## Docs

Documentation can be found at [https://hexdocs.pm/tmp](https://hexdocs.pm/tmp).

## License

Tmp is [MIT licensed](LICENSE).

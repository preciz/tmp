defmodule Tmp do
  @moduledoc """
  Temporary directories that are monitored and automatically removed.
  """

  @doc """
  Creates a temporary directory and passes the path to the given function.

  `function` runs in a new linked GenServer process.
  The directory is automatically removed when the function returns or the
  process terminates.

  To keep the temporary directory for debugging call the function passed as the
  second argument to `function`.

  ## Options

    * `:base_dir` - The directory where `:dirname` is going to be created.
      Defaults to `System.tmp_dir()`.  To customize the default `:base_dir`
      use config: `config :tmp, :default_base_dir, "my_dir"`

    * `:dirname` - The name of the temporary directory.
      Defaults to a random Base16 uid.

    * `:timeout` - How long the function is allowed to run before the
      GenServer call terminates, defaults to :infinity


  ## Examples

      iex> Tmp.dir(fn tmp_dir_path ->
      ...>   Path.join(tmp_dir_path, "my_new_file") |> File.touch()
      ...>   1 + 1
      ...> end)
      2

  To keep the temporary directory for debugging:

      iex> my_file = Tmp.dir(fn tmp_dir_path, keep ->
      ...>   file_path = Path.join(tmp_dir_path, "my_new_file")
      ...>   File.touch(file_path)
      ...>   keep.()
      ...>   file_path
      ...> end)
      ...> File.exists?(my_file)
      true

  """
  @spec dir(function, list) :: term()
  def dir(function, options \\ []) when is_function(function, 1) or is_function(function, 2) do
    base_dir = Keyword.get(options, :base_dir, default_base_dir())
    dirname = Keyword.get(options, :dirname, random_uid())
    timeout = Keyword.get(options, :timeout, :infinity)
    cleaner = Keyword.get(options, :cleaner, Tmp.Cleaner)

    Tmp.Worker.execute(base_dir, dirname, function, timeout, cleaner)
  end

  defp random_uid do
    :crypto.strong_rand_bytes(10) |> Base.encode16(case: :lower)
  end

  defp default_base_dir do
    Application.get_env(:tmp, :default_base_dir) || System.tmp_dir()
  end
end

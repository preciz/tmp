defmodule TmpTest do
  use ExUnit.Case
  doctest Tmp

  test "Auto cleans after process terminates" do
    temp_dir_path =
      Tmp.dir(fn temp_dir_path ->
        temp_dir_path
      end)

    Process.sleep(50)

    refute File.exists?(temp_dir_path)
  end

  test "Temporary directory exists in default base dir" do
    temp_pid =
      Tmp.dir(fn temp_dir_path ->
        assert File.exists?(temp_dir_path)

        assert Path.dirname(temp_dir_path) == System.tmp_dir()
        self()
      end)

    refute Process.alive?(temp_pid)
  end

  test "Temporary process exits when function returns" do
    temp_pid = Tmp.dir(fn _ -> self() end)

    refute Process.alive?(temp_pid)
  end

  test "Temporary directory is removed when parent process exits" do
    test_pid = self()

    pid =
      spawn(fn ->
        Tmp.dir(fn temp_dir_path ->
          send(test_pid, {:temp_dir_path, temp_dir_path})
          Process.sleep(:infinity)
        end)
      end)

    receive do
      {:temp_dir_path, temp_dir_path} ->
        assert File.exists?(temp_dir_path)
        assert Process.alive?(pid)
        Process.exit(pid, :kill)
        Process.sleep(100)
        refute File.exists?(temp_dir_path)
    end
  end
end

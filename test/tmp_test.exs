defmodule TmpTest do
  use ExUnit.Case, async: true
  doctest Tmp

  test "Deletes dir after process terminates" do
    tmp_dir_path =
      Tmp.dir(fn tmp_dir_path ->
        tmp_dir_path
      end)

    Process.sleep(100)

    refute File.exists?(tmp_dir_path)
  end

  test "Returns with return value from function" do
    assert 4 == Tmp.dir(fn _ -> 2 + 2 end)
  end

  test "Runs successfully when base_dir doesn't exists" do
    uid =
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :lower)

    base_dir = "/tmp/#{uid}/"

    assert :ok == Tmp.dir(fn path -> File.touch(Path.join(path, "a")) end, base_dir: base_dir)
  end

  test "temporary directory exists in default base dir" do
    tmp_pid =
      Tmp.dir(fn tmp_dir_path ->
        assert File.exists?(tmp_dir_path)

        assert Path.dirname(tmp_dir_path) == System.tmp_dir()
        self()
      end)

    refute Process.alive?(tmp_pid)
  end

  test "temporary process exits when function returns" do
    tmp_pid = Tmp.dir(fn _ -> self() end)

    refute Process.alive?(tmp_pid)
  end

  test "temporary directory is removed when parent process exits" do
    test_pid = self()

    pid =
      spawn(fn ->
        Tmp.dir(fn tmp_dir_path ->
          send(test_pid, {:tmp_dir_path, tmp_dir_path})
          Process.sleep(:infinity)
        end)
      end)

    receive do
      {:tmp_dir_path, tmp_dir_path} ->
        assert File.exists?(tmp_dir_path)
        assert Process.alive?(pid)
        Process.exit(pid, :kill)
        Process.sleep(100)
        refute File.exists?(tmp_dir_path)
    end
  end

  test "keeps monitored dir if instructed" do
    path =
      Tmp.dir(fn tmp_dir_path ->
        Tmp.keep()

        tmp_dir_path
      end)

    Process.sleep(100)
    assert File.exists?(path)
  end
end

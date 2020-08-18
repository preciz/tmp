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

  test "Returns with return value from function" do
    assert 4 == Tmp.dir(fn _ -> 2 + 2 end)
  end

  test "Keeps the directory if requested" do
    temp_dir_path =
      Tmp.dir(fn temp_dir_path, keep ->
        :ok = keep.()

        temp_dir_path
      end)

    assert File.exists?(temp_dir_path)
  end

  test "Runs successfully when base_dir doesn't exists" do
    uid =
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :lower)

    base_dir = "/tmp/#{uid}/"
    dirname = "yolo"

    assert Path.join(base_dir, dirname) == Tmp.dir(fn path -> path end, base_dir: base_dir, dirname: dirname)
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

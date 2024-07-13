defmodule TmpTest do
  use ExUnit.Case, async: true

  defmodule TestTmp do
    use Tmp
  end

  setup do
    start_supervised!({TestTmp, name: TestTmp})
    :ok
  end

  test "Deletes dir after process terminates" do
    file_path =
      TestTmp.dir(fn tmp_dir_path ->
        file_path = Path.join(tmp_dir_path, "my_file")
        :ok = File.touch(file_path)
        assert File.exists?(file_path)
        file_path
      end)

    Process.sleep(100)
    refute File.exists?(file_path)
  end

  test "Returns with return value from function" do
    assert 4 == TestTmp.dir(fn _ -> 2 + 2 end)
  end

  test "Runs successfully when base_dir doesn't exist" do
    uid =
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :lower)

    base_dir = "/tmp/#{uid}/"

    assert :ok == TestTmp.dir(fn path -> File.touch(Path.join(path, "a")) end, base_dir: base_dir)
  end

  test "temporary directory exists in default base dir" do
    tmp_pid =
      TestTmp.dir(fn tmp_dir_path ->
        assert File.exists?(tmp_dir_path)
        assert Path.dirname(tmp_dir_path) == System.tmp_dir()
        self()
      end)

    refute Process.alive?(tmp_pid)
  end

  test "temporary process exits when function returns" do
    tmp_pid = TestTmp.dir(fn _ -> self() end)
    refute Process.alive?(tmp_pid)
  end

  test "temporary directory is removed when parent process exits" do
    test_pid = self()

    pid =
      spawn(fn ->
        TestTmp.dir(fn tmp_dir_path ->
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

  test "two Tmp Supervisors can be started and used independently" do
    defmodule TestTmp1 do
      use Tmp
    end

    defmodule TestTmp2 do
      use Tmp
    end

    start_supervised!({TestTmp1, name: TestTmp1})
    start_supervised!({TestTmp2, name: TestTmp2})

    tmp1_dir =
      TestTmp1.dir(fn path ->
        assert File.exists?(path)
        path
      end)

    tmp2_dir =
      TestTmp2.dir(fn path ->
        assert File.exists?(path)
        path
      end)

    assert tmp1_dir != tmp2_dir

    # Clean up
    Process.sleep(100)
    refute File.exists?(tmp1_dir)
    refute File.exists?(tmp2_dir)
  end
end

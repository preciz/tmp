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
    {file_path, tmp_dir_path} =
      TestTmp.dir(
        fn tmp_dir_path ->
          assert String.starts_with?(Path.basename(tmp_dir_path), "test_delete_dir-")
          file_path = Path.join(tmp_dir_path, "my_file")
          :ok = File.touch(file_path)
          assert File.exists?(file_path)
          {file_path, tmp_dir_path}
        end,
        prefix: "test_delete_dir"
      )

    Process.sleep(100)
    refute File.exists?(file_path)
    refute File.exists?(tmp_dir_path)
  end

  test "Returns with return value from function" do
    assert 4 == TestTmp.dir(fn _ -> 2 + 2 end, prefix: "test_return_value")
  end

  test "Runs successfully when base_dir doesn't exist" do
    uid =
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :lower)

    base_dir = "/tmp/#{uid}/"

    assert :ok ==
             TestTmp.dir(fn path -> File.touch(Path.join(path, "a")) end,
               base_dir: base_dir,
               prefix: "test_base_dir"
             )

    Process.sleep(100)
    File.rmdir!(base_dir)
  end

  test "temporary directory exists in default base dir with correct prefix" do
    tmp_pid =
      TestTmp.dir(
        fn tmp_dir_path ->
          assert File.exists?(tmp_dir_path)
          assert Path.dirname(tmp_dir_path) == System.tmp_dir()
          assert String.starts_with?(Path.basename(tmp_dir_path), "test_default_base_dir-")
          self()
        end,
        prefix: "test_default_base_dir"
      )

    refute Process.alive?(tmp_pid)
  end

  test "temporary process exits when function returns" do
    tmp_pid = TestTmp.dir(fn _ -> self() end, prefix: "test_process_exit")
    refute Process.alive?(tmp_pid)
  end

  test "temporary directory is removed when parent process exits" do
    test_pid = self()

    pid =
      spawn(fn ->
        TestTmp.dir(
          fn tmp_dir_path ->
            send(test_pid, {:tmp_dir_path, tmp_dir_path})
            Process.sleep(:infinity)
          end,
          prefix: "test_parent_exit"
        )
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
      TestTmp1.dir(
        fn path ->
          assert File.exists?(path)
          path
        end,
        prefix: "test_tmp1"
      )

    tmp2_dir =
      TestTmp2.dir(
        fn path ->
          assert File.exists?(path)
          path
        end,
        prefix: "test_tmp2"
      )

    assert tmp1_dir != tmp2_dir

    # Clean up
    Process.sleep(100)
    refute File.exists?(tmp1_dir)
    refute File.exists?(tmp2_dir)
  end

  test "temporary directory name has correct format with prefix" do
    TestTmp.dir(
      fn tmp_dir_path ->
        dir_name = Path.basename(tmp_dir_path)
        assert String.starts_with?(dir_name, "test_prefix-")
        [prefix, timestamp, random] = String.split(dir_name, "-")
        assert prefix == "test_prefix"
        assert String.length(timestamp) > 0
        {timestamp_int, _} = Integer.parse(timestamp)
        assert is_integer(timestamp_int)
        assert String.length(random) == 10
        assert String.match?(random, ~r/^[a-f0-9]{10}$/)
      end,
      prefix: "test_prefix"
    )
  end

  test "respects timeout option" do
    assert catch_exit(
             TestTmp.dir(fn _ -> Process.sleep(:infinity) end,
               timeout: 100,
               prefix: "test_timeout"
             )
           )
  end

  test "uses base_dir option when provided" do
    custom_base_dir = Path.join(System.tmp_dir(), "custom_base_dir")
    File.mkdir_p!(custom_base_dir)

    TestTmp.dir(
      fn tmp_dir_path ->
        assert String.starts_with?(tmp_dir_path, custom_base_dir)
        assert File.exists?(tmp_dir_path)
      end,
      base_dir: custom_base_dir,
      prefix: "test_custom_base_dir"
    )
  end

  test "uses base_dir from use Tmp when set" do
    defmodule CustomBaseDirTmp do
      use Tmp, base_dir: Path.join(System.tmp_dir(), "custom_base_dir_module")
    end

    start_supervised!({CustomBaseDirTmp, name: CustomBaseDirTmp})

    CustomBaseDirTmp.dir(
      fn tmp_dir_path ->
        assert String.starts_with?(
                 tmp_dir_path,
                 Path.join(System.tmp_dir(), "custom_base_dir_module")
               )

        assert File.exists?(tmp_dir_path)
      end,
      prefix: "test_custom_base_dir_module"
    )
  end

  test "dirname generates correct format with nil prefix" do
    dirname = Tmp.dirname(nil)
    assert String.match?(dirname, ~r/^\d+-[a-f0-9]{10}$/)
  end

  test "dirname generates correct format with non-nil prefix" do
    dirname = Tmp.dirname("test")
    assert String.match?(dirname, ~r/^test-\d+-[a-f0-9]{10}$/)
  end

  test "rand_dirname generates unique names" do
    names = for _ <- 1..100, do: Tmp.rand_dirname()
    assert length(Enum.uniq(names)) == 100
  end
end

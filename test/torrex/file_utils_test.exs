defmodule Torrex.FileUtilsTest do
  use ExUnit.Case, async: :true
  alias Torrex.FileUtils

  test "md5 stream is correct" do
    bytes = :crypto.strong_rand_bytes(64)
    md5 =
      bytes
      |> :erlang.md5()
      |> Base.encode16(case: :lower)
    path = Utils.temp_file(bytes)
    assert FileUtils.md5_stream(path) === md5
  end

  test "single file is sha1 encoded correctly" do
    piece_length = 524
    num_pieces = 1_000
    {final_bytes, final_sha} =
      1..num_pieces
      |> Enum.map(fn _ ->
        bytes = :crypto.strong_rand_bytes(piece_length)
        sha1 = :crypto.hash(:sha, bytes)
        {bytes, sha1}
      end)
      |> Enum.reduce({<<>>, <<>>}, fn {bytes, sha}, {bytes_acc, sha_acc} ->
        {bytes_acc <> bytes, sha_acc <> sha}
      end)
      path = Utils.temp_file(final_bytes)
      assert FileUtils.hash_pieces(path, piece_length) === final_sha
  end

  test "multiple files of even piece size are encoded correctly" do
    piece_length = 524
    num_pieces = 1_000
    num_files = 10
    {reversed_paths, final_sha} =
      1..num_files
      |> Enum.map(fn _ ->
        1..num_pieces
        |> Enum.map(fn _ ->
          bytes = :crypto.strong_rand_bytes(piece_length)
          sha1 = :crypto.hash(:sha, bytes)
          {bytes, sha1}
        end)
        |> Enum.reduce({<<>>, <<>>}, fn {bytes, sha}, {bytes_acc, sha_acc} ->
          {bytes_acc <> bytes, sha_acc <> sha}
        end)
      end)
      |> Enum.map(fn {bytes, sha} ->
        path = Utils.temp_file(bytes)
        {path, sha}
      end)
      |> Enum.reduce({[], <<>>}, fn {path, sha}, {path_acc, sha_acc} ->
        {[path|path_acc], sha_acc <> sha}
      end)
    paths = :lists.reverse(reversed_paths)
    assert FileUtils.hash_pieces(paths, piece_length) === final_sha
  end

  test "multiple files with uneven pieces are encoded correctly" do
    piece_length = 100
    bytes = :crypto.strong_rand_bytes(1024)

    single_file = Utils.temp_file(bytes)
    sha1 = FileUtils.hash_pieces(single_file, piece_length)

    <<file1 :: binary-110, file2 :: binary-110, file3 :: binary-110, file4 :: binary>> = bytes
    files = [Utils.temp_file(file1), Utils.temp_file(file2), Utils.temp_file(file3), Utils.temp_file(file4)]

    assert FileUtils.hash_pieces(files, piece_length) === sha1
  end

  test "traverse directory lists all files" do
    dir = "rand_files"
    File.mkdir!(dir)
    on_exit(fn -> File.rmdir!(dir) end)
    files =
      Enum.map(1..5, fn _ -> Utils.temp_file(<<>>, dir) end)
      |> Enum.sort()

    traversed_files =
      FileUtils.traverse_dir(dir)
      |> Enum.sort()

    assert traversed_files === files
  end
end

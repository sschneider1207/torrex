alias Experimental.Flow
defmodule Torrex.FileUtils do
  @moduledoc """
  Torrent-related file helpers.
  """

  @doc """
  Encodes the sha1 hash for the parts of a file or list of files in a single binary.
  """
  @spec hash_pieces(String.t | [String.t], non_neg_integer) :: <<_::_ * 20>>
  def hash_pieces(paths, piece_length) when is_list(paths) do
    paths
    |> Enum.with_index()
    |> Flow.from_enumerable()
    |> Flow.map(fn {path, index} -> {hash_pieces(path, piece_length), index} end)
    |> Enum.to_list()
    |> Enum.sort_by(fn {_, index} -> index end)
    |> Enum.reduce(<<>>, fn {piece, _index}, acc -> acc <> piece end)
  end
  def hash_pieces(path, piece_length) do
    path
    |> File.stream!([], piece_length)
    |> Stream.map(&:crypto.hash(:sha, &1))
    |> Enum.reduce(<<>>, &Kernel.<>(&2, &1))
  end

  @doc """
  Calculates the md5 of a file as a base-16 encoded string.
  """
  @spec md5_stream(String.t) :: String.t
  def md5_stream(path) do
    path
    |> File.stream!([], 128)
    |> Enum.reduce(:erlang.md5_init(), &:erlang.md5_update(&2, &1))
    |> :erlang.md5_final()
    |> Base.encode16(case: :lower)
  end

  @doc """
  Lists all the files in a directory.
  """
  @spec traverse_dir(String.t, integer) :: [String.t]
  def traverse_dir(directory, timeout \\ 30_000) do
    {dirs, files} =
      directory
      |> File.ls!()
      |> Enum.map(&Path.join(directory, &1))
      |> Enum.partition(&File.dir?/1)

    dir_files =
      dirs
      |> Enum.map(&Task.async(__MODULE__, :traverse_dir, [&1, timeout]))
      |> Enum.map(&Task.await(&1, timeout))
      |> List.flatten()

    files ++ dir_files
  end
end

defmodule Torrex.FileUtils do
  @moduledoc """
  Functions related to hashing files.
  """

  @doc """
  Encodes the sha1 hash for the parts of a file or list of files in a single binary.
  """
  @spec hash_pieces(String.t | [String.t], non_neg_integer) :: <<_::_ * 20>>
  def hash_pieces(paths, piece_length) when is_list(paths) do
    paths
    |> Enum.map(&encode(&1, piece_length))
    |> Enum.reduce(<<>>, &Kernel.<>(&2, &1))
  end
  def encode(path, piece_length) do
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
  Lists all the files in a directory with their paths relative to the directory.
  """
  @spec traverse_dir(String.t) :: [String.t]
  def traverse_dir(path) do
    path
    |> to_charlist()
    |> :filelib.fold_files('.', true, fn name, acc -> [to_string(name)|acc] end, [])
  end
end

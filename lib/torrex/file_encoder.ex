defmodule Torrex.FileEncoder do
  @moduledoc """
  Hashes all the pieces of a file or list of files with the SHA1 algorithm and
  combines them together in a single binary.
  """

  @doc """
  Encodes the sha1 hash for the parts of a file or list of files in a single binary.
  """
  @spec encode(String.t | [String.t], non_neg_integer) :: <<_::_ * 20>>
  def encode(paths, piece_length) when is_list(paths) do
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
end

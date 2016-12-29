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
    do_hash_pieces(paths, piece_length)
    #paths
    #|> Enum.with_index()
    #|> Flow.from_enumerable()
    #|> Flow.map(fn {path, index} -> {hash_pieces(path, piece_length), index} end)
    #|> Enum.to_list()
    #|> Enum.sort_by(fn {_, index} -> index end)
    #|> Enum.reduce(<<>>, fn {piece, _index}, acc -> acc <> piece end)
  end
  def hash_pieces(path, piece_length) do
    path
    |> File.stream!([], piece_length)
    |> Stream.map(&:crypto.hash(:sha, &1))
    |> Enum.reduce(<<>>, &Kernel.<>(&2, &1))
  end

  defp do_hash_pieces(paths, piece_length, acc \\ <<>>)
  defp do_hash_pieces([], _piece_length, final), do: final
  defp do_hash_pieces([path|rest], piece_length, acc) do
    size = :filelib.file_size(path)
    {:ok, file} = :file.open(path, [:read, :raw, :binary])
    case do_hash_piece(file, piece_length, size, acc) do
      {:done, final} ->
        :file.close(file)
        do_hash_pieces(rest, piece_length, final)
      {:rem, final, partial_piece, rem_bytes} ->
        :file.close(file)
        do_hash_pieces_rem(rest, piece_length, final, partial_piece, rem_bytes)
    end
  end

  def do_hash_pieces_rem([], _piece_length, acc, partial_piece, _rem_bytes) do
    acc <> :crypto.hash(:sha, partial_piece)
  end
  def do_hash_pieces_rem([path|rest], piece_length, acc, partial_piece, rem_bytes) do
    size = :filelib.file_size(path)
    {:ok, file} = :file.open(path, [:read, :raw, :binary])
    cond do
      size < rem_bytes ->
        {:ok, partial_bytes} = :file.read(file, size)
        :file.close(file)
        do_hash_pieces_rem(rest, piece_length, acc, partial_piece <> partial_bytes, rem_bytes - size)
      true ->
        {:ok, other_partial_piece} = :file.read(file, rem_bytes)
        acc = acc <> :crypto.hash(:sha, partial_piece <> other_partial_piece)
        case do_hash_piece(file, piece_length, size, acc, rem_bytes) do
          {:done, final} ->
            :file.close(file)
            do_hash_pieces(rest, piece_length, final)
          {:rem, final, partial_piece, rem_bytes} ->
            :file.close(file)
            do_hash_pieces_rem(rest, piece_length, final, partial_piece, rem_bytes)
        end
    end
  end

  defp do_hash_piece(file, piece_length, total, acc, read \\ 0)
  defp do_hash_piece(_file, _piece_length, total, final, total), do: {:done, final}
  defp do_hash_piece(file, piece_length, total, acc, read) when read + piece_length <= total  do
    {:ok, iodata} = :file.read(file, piece_length)
    bytes = :erlang.iolist_to_binary(iodata)
    acc = acc <> :crypto.hash(:sha, bytes)
    do_hash_piece(file, piece_length, total, acc, read + piece_length)
  end
  defp do_hash_piece(file, piece_length, total, final, read) do
    rem = total - read
    {:ok, bytes} = :file.read(file, rem)
    {:rem, final, bytes, piece_length - rem}
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

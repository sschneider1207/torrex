defmodule Torrex do
  @moduledoc """
  Generate .torrent files for single files and directories.
  """
  @default_piece_length 524_288 # 512 KiB

  @type options :: [option]

  @type option ::
    piece_length |
    announce_list |
    creation_date |
    comment |
    created_by |
    private |
    md5sum

  @type piece_length :: {:piece_length, integer}

  @type announce_list :: {:announce_list, [String.t]}

  @type creation_date :: {:creation_date, boolean}

  @type comment :: {:comment, String.t}

  @type created_by :: {:created_by, String.t}

  @type private :: {:private, boolean}

  @type md5sum :: {:md5sum, boolean}

  @doc """
  Generates a .torrent file for a single file.
  """
  def single_file(path, announce, opts \\ []) do
    piece_length = opts[:piece_length] || @default_piece_length
    dict = %{
      info: %{},
      announce: announce
    }
  end

  defp encode_info(:single_file, path, piece_length) do

  end

  @doc """
  Decodes a .torrent file.
  """
  @spec decode(String.t) :: map
  def decode(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_list()
    |> Benx.decode!()
  end
end

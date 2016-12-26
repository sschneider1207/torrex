defmodule Torrex do
  @moduledoc """
  Generate .torrent files for single files and directories.
  """
  alias Torrex.FileUtils
  @default_piece_length 524_288 # 512 KiB

  @typedoc """
  Encodable types.
  """
  @type encodable :: file | directory

  @typedoc """
  Path to a file.
  """
  @type file :: String.t

  @typedoc """
  Path to a directory of files.
  """
  @type directory :: String.t

  @type options :: [option]

  @type option ::
    piece_length |
    output |
    announce_list |
    creation_date |
    comment |
    created_by |
    private |
    md5sum

  @typedoc """
  Length of each file piece in the torrent.  Defaults to 512 KiB.
  """
  @type piece_length :: {:piece_length, integer}

  @typedoc """
  Name of the output .torrent file.  Defaults to provided file/directory name.
  """
  @type output :: {:output, String.t}

  @typedoc """
  List of announce URLs (optional).
  """
  @type announce_list :: {:announce_list, [String.t]}

  @typedoc """
  Include the creation time of the torrent, in standard UNIX epoch format (optional).
  Defaults to true.
  """
  @type creation_date :: {:creation_date, boolean}

  @typedoc """
  Include a free-form textual comment (optional).
  """
  @type comment :: {:comment, String.t}

  @typedoc """
  Name of version of the program used to create the .torrent (optional).
  """
  @type created_by :: {:created_by, String.t}

  @typedoc """
  Is the torrent private (optional)?  Defaults to false.
  """
  @type private :: {:private, boolean}

  @typedoc """
  Include an md5 of all files in the torrent (optional).  Defaults to false.
  """
  @type md5sum :: {:md5sum, boolean}

  @doc """
  Encodes a file or directory to a .torrent file.
  """
  @spec encode(encodable, String.t, options) :: {:ok, String.t}
  def encode(path, announce, opts \\ []) do
    type = case File.dir?(path) do
      true -> :dir
      _ -> :file
    end
    piece_length = opts[:piece_length] || @default_piece_length
    %{
      "info" => encode_info(type, path, piece_length, opts),
      "announce" => announce,
      "encoding" => "UTF-8"
    }
    |> set_options(opts)
    |> write_to_file(path, opts)
  end

  defp encode_info(:file, path, piece_length, opts) do
    %{
      "piece length" => piece_length,
      "pieces" => FileUtils.hash_pieces(path, piece_length),
      "name" => Path.basename(path),
      "length" => File.stat!(path).size
    }
    |> set_private(opts)
    |> maybe_set_md5(path, opts)
  end

  defp encode_info(:dir, path, piece_length, opts) do
    files = FileUtils.traverse_dir(path)
    %{
      "piece length" => piece_length,
      "pieces" => FileUtils.hash_pieces(files, piece_length),
      "name" => Path.basename(path),
      "files" => encode_files(files, path, opts)
    }
    |> set_private(opts)
  end

  defp encode_files(files, base_dir, opts) do
    Enum.map(files, fn path ->
      %{
        "length" => File.stat!(path).size,
        "path" => encode_path(path, base_dir)
      }
      |> maybe_set_md5(path, opts)
    end)
  end

  defp encode_path(path, base_dir) do
    path
    |> Path.relative_to(base_dir)
    |> Path.split()
  end

  defp set_private(info, opts) do
    case opts[:private] || false do
      true -> Map.put(info, "private", 1)
      _ -> Map.put(info, "private", 0)
    end
  end

  defp maybe_set_md5(info, path, opts) do
    case opts[:md5sum] || false do
      true -> Map.put(info, "md5sum", FileUtils.md5_stream(path))
      _ -> info
    end
  end

  defp set_options(dict, opts) do
    dict
    |> maybe_set_announce_list(opts)
    |> maybe_set_creation_date(opts)
    |> maybe_set_comment(opts)
    |> maybe_set_created_by(opts)
  end

  defp maybe_set_announce_list(dict, opts) do
    case opts[:announce_list] do
      list when is_list(list) -> Map.put(dict, "announce-list", list)
      _ -> dict
    end
  end

  defp maybe_set_creation_date(dict, opts) do
    case opts[:creation_date] || true do
      true -> Map.put(dict, "creation date", :os.system_time(:seconds))
      _ -> dict
    end
  end

  defp maybe_set_comment(dict, opts) do
    case opts[:comment] do
      comment when is_bitstring(comment) -> Map.put(dict, "comment", comment)
      _ -> dict
    end
  end

  defp maybe_set_created_by(dict, opts) do
    case opts[:created_by] do
      author when is_bitstring(author) -> Map.put(dict, "created by", author)
      _ -> dict
    end
  end

  defp write_to_file(dict, path, opts) do
    iodata = Benx.encode(dict)
    name = determine_torrent_name(path, opts)
    File.write!(name, iodata)
    name
  end

  defp determine_torrent_name(path, opts) do
    case opts[:output] do
      name when is_bitstring(name) -> name
      _ -> name_from_path(path)
    end
    |> Kernel.<>(".torrent")
  end

  defp name_from_path(path) do
    case File.dir?(path) do
      true -> path
      _ -> Path.rootname(path)
    end
    |> Path.split()
    |> List.last()
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

ExUnit.start()

defmodule Utils do

  def temp_path do
    name =
      :crypto.strong_rand_bytes(16)
      |> Base.encode16(case: :lower)
    path =
      System.tmp_dir!()
      |> Path.join(name)
    ExUnit.Callbacks.on_exit(fn -> File.rm!(path) end)
    path
  end

  def temp_file(data) do
    path = temp_path()
    File.write!(path, data)
    path
  end
end

ExUnit.start()

defmodule Utils do

  def temp_path(base \\ "") do
    name =
      :crypto.strong_rand_bytes(16)
      |> Base.encode16(case: :lower)
    path = Path.join(base, name)
    ExUnit.Callbacks.on_exit(fn -> File.rm!(path) end)
    path
  end

  def temp_file(data, base \\ "") do
    path = temp_path(base)
    File.write!(path, data)
    path
  end
end

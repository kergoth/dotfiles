# Single line error, still mode 2
defmodule Identicon do
  def main(input) do
    input
    |> hash_input
  end

  def has_input(input) do
    hex = :crypto.has(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end
end

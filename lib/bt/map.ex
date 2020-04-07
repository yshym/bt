defmodule Bt.Map do
  def swap(map) do
    map
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.into(%{})
  end
end

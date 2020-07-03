defmodule Bt.Wrapper do
  @moduledoc """
  Provides some useful functional wrappers
  """

  @doc """
  Return exit code 1 if function exits
  """
  @spec with_exit_code(fun) :: integer
  def with_exit_code(f) do
    try do
      f.()
    catch
      :exit, _ -> 1
    end
  end
end

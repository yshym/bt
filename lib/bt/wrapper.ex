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

  @doc """
  Return default value if function exits
  """
  @spec with_default_value(fun, term) :: term
  def with_default_value(f, v) do
    try do
      f.()
    catch
      :exit, _ -> v
    end
  end
end

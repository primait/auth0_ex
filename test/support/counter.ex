defmodule PrimaAuth0Ex.TestSupport.Counter do
  @moduledoc """
  A simple counter for testing purposes.
  """

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end)
  end

  def count(agent) do
    Agent.get(agent, & &1)
  end

  def increment(agent) do
    Agent.update(agent, &(&1 + 1))
  end
end

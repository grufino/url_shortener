defmodule UrlShortener.TaskMock do

  @moduledoc """
    This module exists because in case of tests, Task.start will always fail,
    as it will occur asynchronously, and therefore the database/table/registry,
    may not exist anymore. This module only executes start synchronously.
  """

  def start(fun) do
    fun.()
  end
end

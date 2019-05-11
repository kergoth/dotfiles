defmodule Proj do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil, name: :kv_server)
  end

  def put(key, val) do
    GenServer.cast(:kv_server, {:put, key, val})
  end

  def get(key) do
    GenServer.call(:kv_server, {:get, key})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get, key}, _caller, state) do
    prepare_for_call
    {:reply, Map.get(state, key), state}
  end

  def handle_cast({:put, key, val}, state) do
    {:noreply, Map.put(state, key, val), state}
  end

  def prepare_for_call() do
    :ok
  end

end

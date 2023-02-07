defmodule NiffSaid.Nif do
  @on_load :init

  def init do
    :ok = :erlang.load_nif('./priv/nif', 0)
  end

  def sum(_, _), do: :erlang.nif_error(:not_loaded)
  def create, do: :erlang.nif_error(:not_loaded)
  def create(_), do: :erlang.nif_error(:not_loaded)
  def set(_, _), do: :erlang.nif_error(:not_loaded)
  def fetch(_), do: :erlang.nif_error(:not_loaded)
end

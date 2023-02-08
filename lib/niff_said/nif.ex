defmodule NiffSaid.Nif do
  @on_load :load_nifs

  def load_nifs, do: :erlang.load_nif('./priv/nif', 0)
  def sum(_, _), do: :erlang.nif_error(:not_loaded)
  def create, do: :erlang.nif_error(:not_loaded)
  def create(_), do: :erlang.nif_error(:not_loaded)
  def set(_, _), do: :erlang.nif_error(:not_loaded)
  def fetch(_), do: :erlang.nif_error(:not_loaded)
  def fast_compare(_, _), do: :erlang.nif_error(:not_loaded)
  def hello, do: :erlang.nif_error(:not_loaded)
end

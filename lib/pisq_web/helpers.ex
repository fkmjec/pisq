defmodule PisqWeb.Helpers do
  def hide_when(condition) do
    case condition do
      true -> "d-none"
      false -> ""
    end
  end
end

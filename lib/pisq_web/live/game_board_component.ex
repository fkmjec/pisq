defmodule PisqWeb.Live.GameBoardComponent do
  use PisqWeb, :live_component

  def render(assigns) do
    ~L"""
      <div>
      <table class="game-board">
        <%= for y <- 0..Application.get_env(:pisq, :board_y)-1 do %>
          <tr>
          <%= for x <- 0..Application.get_env(:pisq, :board_x)-1 do %>
            <td class="game-field-cell">
              <a class="game-field <%= hide_when(@board[{x, y}] != nil) %>" href="#"
              phx-click="place_symbol"
              phx-value-x="<%= x %>"
              phx-value-y="<%= y %>">
              <%= raw get_symbol_to_display(@board, x, y) %>
              </a>
              <span class="game-field <%= hide_when(@board[{x, y}] == nil) %>">
              <%= raw get_symbol_to_display(@board, x, y) %>
              </span>
            </td>
          <% end %>
          </tr>
        <% end %>
      </table>
      </div>
    """
  end

  defp get_symbol_to_display(board, x, y) do
    case board[{x, y}] do
      nil -> "&nbsp;"
      :cross -> "x"
      :circle -> "o"
      _ -> "something went wrong"
    end
  end

  defp hide_when(condition) do
    case condition do
      true -> "d-none"
      false -> ""
    end
  end
end

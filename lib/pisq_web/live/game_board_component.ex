defmodule PisqWeb.Live.GameBoardComponent do
  use PisqWeb, :live_component
  alias PisqWeb.Helpers, as: Helpers

  def render(assigns) do
    ~L"""
      <div class="is-centered">
      <table class="game-board">
        <%= for y <- 0..Application.get_env(:pisq, :board_y)-1 do %>
          <tr class="game-field-row">
          <%= for x <- 0..Application.get_env(:pisq, :board_x)-1 do %>
            <td class="game-field-cell">
              <a class="game-field <%= Helpers.hide_when(@board[{x, y}] != nil or !@can_play) %>" href="#"
              phx-click="place_symbol"
              phx-value-x="<%= x %>"
              phx-value-y="<%= y %>">
              <span class="symbol"><%= raw get_symbol_to_display(@board, @winning_positions, x, y) %></span>
              </a>
              <span class="taken-field <%= Helpers.hide_when(@board[{x, y}] == nil) %>">
              <span class="symbol"><%= raw get_symbol_to_display(@board, @winning_positions, x, y) %></span>
              </span>
            </td>
          <% end %>
          </tr>
        <% end %>
      </table>
      </div>
    """
  end

  defp get_symbol_to_display(board, winning_positions, x, y) do
    color = case winning_positions[{x, y}] do
      true -> "red"
      nil -> "black"
    end
    case board[{x, y}] do
      nil -> "&nbsp;"
      :crosses -> """
      <svg
        version="1.1"
        id="Capa_1"
        x="0px"
        y="0px"
        viewBox="0 0 20 20.000002"
        xml:space="preserve"
        width="20"
        height="20.000002"
        xmlns="http://www.w3.org/2000/svg"
        xmlns:svg="http://www.w3.org/2000/svg"><defs
        id="defs1024" />
      <polygon
        points="0.708,457.678 33.149,490 245,277.443 456.851,490 489.292,457.678 277.331,245.004 489.292,32.337 456.851,0 245,212.564 33.149,0 0.708,32.337 212.669,245.004 "
        id="polygon989"
        style="fill:#{color}; stroke:#{color}"
        transform="matrix(0.04093462,0,0,0.04081633,-0.02898171,0)" />
      </svg>
      """
      :circles -> """
      <svg height="30" width="30">
      <circle cx="15" cy="11" r="10" stroke="#{color}" stroke-width="2" fill="white" />
      </svg>
      """
      _ -> "something went wrong"
    end
  end
end

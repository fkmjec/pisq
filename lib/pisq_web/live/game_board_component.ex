defmodule PisqWeb.Live.GameBoardComponent do
  use PisqWeb, :live_component

  def render(assigns) do
    ~L"""
      <div style="display:flex;flex-direction:column; height:100%;">
      <table>
        <%= for y <- 0..Application.get_env(:pisq, :board_y)-1 do %>
          <tr>
          <%= for x <- 0..Application.get_env(:pisq, :board_x)-1 do %>
          <td style="border:1px solid black; width:10px; height:10px;">
            <a href="#"
            phx-click="place_symbol"
            phx-value-x="1"
            phx-value-y="2">
            </a>
            </td>
          <% end %>
          </tr>
        <% end %>
      </table>
      </div>
    """
  end
end

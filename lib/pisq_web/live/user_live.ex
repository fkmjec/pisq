defmodule PisqWeb.Live.UserLive do
  use PisqWeb, :live_view
  alias PisqWeb.Endpoint
  alias Pisq.Utils.GameUtils

  @module "UserLive"

#   defp topic(team_id), do: "team:#{team_id}"

  def render(assigns) do
    ~L"""
    <h3> User <%= @id %> </h3>
    <div class="container-fluid px-0">
    <div style="display:flex;flex-direction:column; height:100%;">
      <table>
        <%= for y <- 0..Application.get_env(:pisq, :board_y)-1 do %>
          <tr>
          <%= for x <- 0..Application.get_env(:pisq, :board_x)-1 do %>
          <td style="border:1px solid black; width:10px; height:10px;">
            <a href="#"
            phx-click="place_symbol"
            phx-value-x="<%= x %>"
            phx-value-y="<%= y %>">
              <%= raw get_symbol_to_display(@board, x, y) %>
            </a>
            </td>
          <% end %>
          </tr>
        <% end %>
      </table>
    </div>
    <div class="container-fluid">
      <!-- TODO Flash messages -->
    </div>
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

  def mount(params, _session, socket) do
    id = params["id"]
    board = GameUtils.get_game_board(id)
    socket = assign(socket, :id, id)
    |> assign(:board, board)

    Endpoint.subscribe(id)
    {:ok, socket}
  end

  def handle_info(%{event: "board_update", payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  def handle_event(
    "place_symbol",
    %{"x" => str_x, "y" => str_y},
    socket
  ) do
    { x, "" } = Integer.parse(str_x)
    { y, "" } = Integer.parse(str_y)
    id = socket.assigns.id
    case GameUtils.place_symbol(id, x, y) do
      {:ok, %{board: board}} -> {:noreply, assign(socket, :board, board)}
      {:error, message} ->
        socket = put_flash(socket, :error, message)
        {:noreply, socket} # TODO error handling
      _ -> {:noreply, socket} # should never happen
    end
  end

#   def handle_event(
#     "refresh_problem",
#     %{ "problem_id" => problem_id } = input,
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "refresh_problem", input)
#     { problem_id, "" } = Integer.parse(problem_id)
#     problem =
#       Problems.get_team_problems(user)
#       |> Enum.find(nil, fn problem -> problem.id === problem_id end)

#     socket =
#       case problem do
#         nil -> socket
#         problem -> assign(socket, problems: [problem])
#       end
#     log_end(@module, "refresh_problem")
#     {:noreply, socket}
#   end

#   def handle_event(
#     "solve_problem",
#     %{ "team_solution" => team_solution },
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "solve_problem", team_solution)
#     socket =
#       case Problems.solve_problem(user, team_solution) do
#         {:ok, problem} ->
#           problems = [problem, List.last(Problems.get_team_problems(user))]
#           GenServer.cast({:global, "team-#{user.team.id}"}, {:problem_solved, %{
#             points: Application.get_env(:maso_online, :points_per_problem),
#             dice_roll: problem.dice_roll
#           }})
#           Endpoint.broadcast_from(self(), topic(user.team.id), "team_update", %{problems: problems})
#           assign(socket, problems: problems)

#         {:mistake, problem} ->
#           Endpoint.broadcast_from(self(), topic(user.team.id), "team_update", %{problems: [problem]})
#           assign(socket, problems: [problem])

#         {:error, problem} ->
#           assign(socket, problems: [problem])
#       end
#     log_end(@module, "solve_problem")
#     {:noreply, socket}
#   end

#   def handle_event(
#     "exchange_problem",
#     %{ "problem_id" => problem_id } = params,
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "exchange_problem", params)
#     problems = Problems.exchange_problem(user, problem_id)
#     exchanged_problems = Problems.get_exchanged_team_problems(user.team.id)
#     Endpoint.broadcast_from(self(), topic(user.team.id), "team_update", %{problems: problems, exchanged_problems: exchanged_problems})
#     socket = assign(socket, problems: problems, exchanged_problems: exchanged_problems)
#     log_end(@module, "exchange_problem", Enum.map(problems, fn p -> p.id end))
#     {:noreply, socket}
#   end

#   def handle_event(
#     "move",
#     %{ "dice_roll" => dice_roll_str } = params,
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "move", params)
#     { dice_roll, "" } = Integer.parse(dice_roll_str)
#     data = %{dice_roll: dice_roll}
#     socket = case GenServer.call({:global, "team-#{user.team.id}"}, {:move,  data}) do
#       {:ok, _team_state} ->
#         # team state synchronized through the whole team
#         socket
#       {:error, message} ->
#         put_flash(socket, :error, message)
#     end
#     log_end(@module, "move")
#     {:noreply, socket}
#   end

#   # def handle_event(
#   #   "add_random_dice",
#   #   %{} = params,
#   #   %{ assigns: %{ :current_user => user } } = socket
#   # ) do
#   #   log_start(@module, "add_random_dice", params)
#   #   socket = case GenServer.call({:global, "team-#{user.team.id}"}, :add_random_dice) do
#   #     {:ok, _team_state} ->
#   #       # team state synchronized through the whole team
#   #       socket
#   #     {:error, message} ->
#   #       put_flash(socket, :error, message)
#   #   end
#   #   log_end(@module, "add_random_dice")
#   #   {:noreply, socket}
#   # end

#   def handle_event(
#     "toggle_upgrade",
#     %{ "upgrade_type" => upgrade_type_str } = params,
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "toggle_upgrade", params)
#     upgrade = SnakesUtils.get_upgrade_type_from_str(upgrade_type_str)
#     socket = case GenServer.call({:global, "team-#{user.team.id}"}, {:toggle_upgrade, %{ upgrade: upgrade }}) do
#       {:ok, _team_state} ->
#         # team state synchronized through the whole team
#         socket
#       {:error, message} ->
#         put_flash(socket, :error, message)
#     end
#     log_end(@module, "toggle_upgrade")
#     {:noreply, socket}
#   end

#   def handle_event(
#     "start_multiplier",
#     params,
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "start_multiplier", params)
#     socket = case GenServer.call({:global, "team-#{user.team.id}"}, {:start_multiplier}) do
#       {:ok, _team_state} ->
#         # team state synchronized through the whole team
#         socket
#       {:error, message} ->
#         put_flash(socket, :error, message)
#     end
#     log_end(@module, "start_multiplier")
#     {:noreply, socket}
#   end

#   def handle_event(
#     "flip_ladders",
#     params,
#     %{ assigns: %{ :current_user => user } } = socket
#   ) do
#     log_start(@module, "flip_ladders", params)
#     socket = case GenServer.call({:global, "team-#{user.team.id}"}, {:flip_ladders}) do
#       {:ok, _team_state} ->
#         # team state synchronized through the whole team
#         socket
#       {:error, message} ->
#         put_flash(socket, :error, message)
#     end
#     log_end(@module, "flip_ladders")
#     {:noreply, socket}
#   end

#   # def handle_event(
#   #   "place_wall",
#   #   %{ "x" => x, "y" => y } = params,
#   #   %{ assigns: %{ :current_user => user } } = socket
#   # ) do
#   #   log_start(@module, "place_wall", params)
#   #   data = %{competitor: user, position: {x, y}}
#   #   socket = case GenServer.call({:global, "team-#{user.team.id}"}, {:place_wall,  data}) do
#   #     {:ok, _team_state} ->
#   #       # team state synchronized through the whole team
#   #       socket
#   #     {:error, message} ->
#   #       put_flash(socket, :error, message)
#   #   end
#   #   log_end(@module, "place_wall")
#   #   {:noreply, socket}
#   # end

#   def handle_info(%{event: "team_update", payload: state}, socket) do
#     state = Map.put(state, :time_now, DateTime.utc_now())
#     {:noreply, assign(socket, state)}
#   end

#   def handle_info(%{event: "event_update", payload: state}, %{ assigns: %{ :current_user => _user } } = socket) do
#     state = if Map.has_key?(state, :period_just_changed) && state.period_just_changed, do: Map.put(state, :problems, Problems.get_team_problems(socket.assigns.current_user)), else: state
#     state = Map.put(state, :time_now, DateTime.utc_now())
#     {:noreply, assign(socket, state)}
#   end

#   defp hide_when(period, values) do
#     if period in values, do: "d-none", else: ""
#   end
end

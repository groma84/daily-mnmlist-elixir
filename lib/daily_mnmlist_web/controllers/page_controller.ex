defmodule DailyMnmlistWeb.PageController do
  use DailyMnmlistWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

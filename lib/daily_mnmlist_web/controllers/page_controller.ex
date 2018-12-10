defmodule DailyMnmlistWeb.PageController do
  require Logger

  use DailyMnmlistWeb, :controller

  def index(conn, _params) do
    {_date, link} = DailyMnmlist.Workflows.get_data_for_today(NaiveDateTime.utc_now())
    redirect(conn, external: link.link)
  end
end

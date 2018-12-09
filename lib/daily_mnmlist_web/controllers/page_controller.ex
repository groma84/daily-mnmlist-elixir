defmodule DailyMnmlistWeb.PageController do
  use DailyMnmlistWeb, :controller

  def index(conn, _params) do
    {_date, {link, _title}} = DailyMnmlist.Workflows.get_data_for_today(NaiveDateTime.utc_now())
    redirect(conn, external: link)
  end
end

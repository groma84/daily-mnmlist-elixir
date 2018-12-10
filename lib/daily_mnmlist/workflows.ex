defmodule DailyMnmlist.Workflows do
  import DailyMnmlist.Link

  @spec get_data_for_today(NaiveDateTime.t()) :: {Date, any()}
  def get_data_for_today(today) do
    DailyMnmlist.Datastore.retrieve_data_for_date(today)
  end
end

defmodule DailyMnmlist.Workflows do
  require Logger

  @table_name :links
  @url 'http://mnmlist.com/archives/'

  @type link() :: {String.t(), String.t()}

  @spec get_data_for_today(NaiveDateTime.t()) :: {Date, link()}
  def get_data_for_today(today) do
    create_datastore_if_not_exists(@table_name)

    case retrieve_data_for_today(today, @table_name) do
      {:not_found, _} ->
        Logger.info("getting fresh data")
        get_fresh_data_and_insert_into_datastore(today, @table_name, @url)
        get_data_for_today(today)

      {:ok, link} ->
        Logger.info("returning already cached data")
        link
    end
  end

  defp download_page(url) do
    Application.ensure_all_started(:inets)

    {:ok, resp} = :httpc.request(url)
    {{_, 200, 'OK'}, _headers, body} = resp

    # body is a String.Chars list initially
    body |> String.Chars.to_string()
  end

  @spec parse_html(String.t()) :: [link()]
  defp parse_html(html) do
    Floki.find(html, "a")
    |> Enum.map(&extract_data/1)
  end

  @spec randomize_links([link()]) :: [link()]
  defp randomize_links(links) do
    Enum.shuffle(links)
  end

  @spec combine_links_with_dates([link()], NaiveDateTime.t()) :: [{link(), NaiveDateTime.t()}]
  defp combine_links_with_dates(links, start_date) do
    create_dates(start_date, Enum.count(links))
    |> Enum.zip(links)
  end

  defp retrieve_data_for_today(date, table_name) do
    case :ets.lookup(table_name, NaiveDateTime.to_date(date)) do
      [] -> {:not_found, []}
      [link] -> {:ok, link}
    end
  end

  defp get_fresh_data_and_insert_into_datastore(date, table_name, from_url) do
    download_page(from_url)
    |> parse_html()
    |> randomize_links()
    |> combine_links_with_dates(date)
    |> insert_into_datastore(table_name)
  end

  defp extract_data(node) do
    [href] = Floki.attribute(node, "href")
    text = Floki.text(node) |> remove_unwanted_chars

    {href, text}
  end

  defp remove_unwanted_chars(text) do
    text
    |> String.replace_leading("\r", "")
    |> String.replace_leading("\n", "")
    |> String.replace_leading("\t", "")
  end

  defp create_dates(start_date, length) do
    for n <- 0..(length - 1) do
      NaiveDateTime.add(start_date, 60 * 60 * 24 * n)
      |> NaiveDateTime.to_date()
    end
  end

  defp create_datastore_if_not_exists(table_name) do
    case :ets.info(table_name) do
      :undefined ->
        Logger.info("created datastore with table #{table_name}")
        :ets.new(table_name, [:named_table])
        :ok

      _ ->
        :ok
    end
  end

  defp insert_into_datastore(links, table_name) do
    links
    |> Enum.each(&:ets.insert(table_name, &1))
  end
end

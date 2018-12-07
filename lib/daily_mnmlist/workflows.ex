defmodule DailyMnmlist.Workflows do
  @type link() :: {String.t(), String.t()}

  defp download_mnmlist() do
    download_page('http://mnmlist.com/archives/')
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

  def get_data_for_today(today) do
    case :ets.info(:links) do
      :undefined ->
        get_fresh_data_and_insert_into_datastore(today)
        retrieve_data_for_today(today)

      _ ->
        retrieve_data_for_today(today)
    end
  end

  defp retrieve_data_for_today(date) do
    :ets.lookup(:links, NaiveDateTime.to_date(date))
  end

  defp get_fresh_data_and_insert_into_datastore(date) do
    download_mnmlist()
    |> parse_html()
    |> randomize_links()
    |> combine_links_with_dates(date)
    |> insert_into_datastore()
  end

  defp extract_data(node) do
    href = Floki.attribute(node, "href")
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

  defp insert_into_datastore(links) do
    :ets.new(:links, [:named_table])

    links
    |> Enum.each(&:ets.insert(:links, &1))
  end
end

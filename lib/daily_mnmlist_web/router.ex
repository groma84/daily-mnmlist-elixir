defmodule DailyMnmlistWeb.Router do
  use DailyMnmlistWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope "/", DailyMnmlistWeb do
    pipe_through :browser
    get "/", PageController, :index
  end
end

defmodule Auth0Ex.Consumer.AuthorizationService do
  @moduledoc false

  require Logger

  def retrieve_token(audience \\ default_audience()) do
    url()
    |> Telepoison.post(body(audience), "content-type": "application/json")
    |> parse_response()
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, %{"token_type" => "Bearer", "access_token" => access_token}} -> {:ok, access_token}
      _ -> {:error, :invalid_auth0_response}
    end
  end

  defp parse_response(_invalid_response) do
    {:error, :request_error}
  end

  defp body(audience) do
    %{
      grant_type: "client_credentials",
      client_id: client_id(),
      client_secret: client_secret(),
      audience: audience
    }
    |> Jason.encode!()
  end

  defp url do
    "https://#{domain()}/oauth/token"
  end

  defp domain, do: Application.fetch_env!(:auth0_ex, :domain)
  defp default_audience, do: Application.fetch_env!(:auth0_ex, :default_audience)
  defp client_id, do: Application.fetch_env!(:auth0_ex, :client_id)
  defp client_secret, do: Application.fetch_env!(:auth0_ex, :client_secret)
end

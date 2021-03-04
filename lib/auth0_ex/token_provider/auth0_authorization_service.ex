defmodule Auth0Ex.TokenProvider.Auth0AuthorizationService do
  @moduledoc false
  @behaviour Auth0Ex.TokenProvider.AuthorizationService

  require Logger

  @auth0_token_api_path "/oauth/token"

  @impl Auth0Ex.TokenProvider.AuthorizationService
  def retrieve_token(credentials, audience) do
    request_body = body(credentials, audience)
    url = credentials.base_url <> @auth0_token_api_path

    url
    |> Telepoison.post(request_body, "content-type": "application/json")
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

  defp body(credentials, audience) do
    %{
      grant_type: "client_credentials",
      client_id: credentials.client_id,
      client_secret: credentials.client_secret,
      audience: audience
    }
    |> Jason.encode!()
  end
end

defmodule Auth0Ex.Consumer.Auth0AuthorizationService do
  @moduledoc false
  @behaviour Auth0Ex.Consumer.AuthorizationService

  require Logger

  @auth0_token_api_path "/oauth/token"

  def retrieve_token(base_url, client_id, client_secret, audience) do
    request_body = body(client_id, client_secret, audience)
    url = base_url <> @auth0_token_api_path

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

  defp body(client_id, client_secret, audience) do
    %{
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret,
      audience: audience
    }
    |> Jason.encode!()
  end
end

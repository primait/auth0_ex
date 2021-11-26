defmodule PrimaAuth0Ex.TokenProvider.Auth0AuthorizationService do
  @moduledoc """
  Implementation of `PrimaAuth0Ex.TokenProvider.AuthorizationService` for Auth0.
  """

  @behaviour PrimaAuth0Ex.TokenProvider.AuthorizationService

  require Logger
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @auth0_token_api_path "/oauth/token"

  @impl PrimaAuth0Ex.TokenProvider.AuthorizationService
  def retrieve_token(credentials, audience) do
    request_body = body(credentials, audience)
    url = credentials.base_url <> @auth0_token_api_path

    Logger.info("Requesting token to Auth0", audience: audience, url: url)

    url
    |> Telepoison.post(request_body, "content-type": "application/json")
    |> parse_response()
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, %{"token_type" => "Bearer", "access_token" => access_token}} ->
        {:ok, TokenInfo.from_jwt(access_token)}

      response ->
        Logger.warn("Invalid response from Auth0", response: inspect(response))
        {:error, :invalid_auth0_response}
    end
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: status_code}}) do
    Logger.warn("Request to Auth0 failed", status_code: status_code)
    {:error, :request_error}
  end

  defp parse_response({:error, message}) do
    Logger.warn("Error sending request to Auth0", error: inspect(message))
    {:error, message}
  end

  defp body(credentials, audience) do
    Jason.encode!(%{
      grant_type: "client_credentials",
      client_id: credentials.client_id,
      client_secret: credentials.client_secret,
      audience: audience
    })
  end
end

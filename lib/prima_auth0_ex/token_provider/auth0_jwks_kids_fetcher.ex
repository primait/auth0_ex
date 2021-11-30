defmodule PrimaAuth0Ex.TokenProvider.Auth0JwksKidsFetcher do
  @moduledoc """
  Fetches key ids (aka `kid`s) from Auth0 JWKS
  """
  require Logger
  alias PrimaAuth0Ex.TokenProvider.JwksKidsFetcher

  @behaviour JwksKidsFetcher

  @auth0_jwks_api_path "/.well-known/jwks.json"

  @spec fetch_kids(PrimaAuth0Ex.Auth0Credentials.t()) :: {:ok, [String.t()]} | {:error, any()}
  @impl JwksKidsFetcher
  def fetch_kids(credentials) do
    jwks_url = credentials.base_url <> @auth0_jwks_api_path

    jwks_url
    |> Telepoison.get()
    |> parse_body()
    |> extract_kids()
  end

  defp parse_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, jwks} ->
        jwks

      {:error, error} ->
        Logger.warning("Error parsing JWKS", error: inspect(error))
        {:error, error}
    end
  end

  defp parse_body(error_response) do
    Logger.warning("Error retrieving JWKS", response: inspect(error_response))
    {:error, error_response}
  end

  defp extract_kids({:error, reason}), do: {:error, reason}

  defp extract_kids(jwks) do
    case get_in(jwks, ["keys", Access.all(), "kid"]) do
      nil ->
        Logger.warning("Error parsing kids from JWKS", jwks: inspect(jwks))
        {:error, :malformed_jwks}

      kids ->
        {:ok, kids}
    end
  rescue
    error ->
      Logger.warning("Error parsing kids from JWKS", jwks: inspect(jwks), error: inspect(error))
      {:error, :malformed_jwks}
  end
end

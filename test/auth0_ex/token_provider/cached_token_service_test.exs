defmodule Auth0Ex.TokenProvider.CachedTokenServiceTest do
  use ExUnit.Case, async: true

  import Hammox
  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.TokenProvider.CachedTokenService

  @credentials %Auth0Credentials{base_url: "base_url", client_id: "client_id", client_secret: "client_secret"}

  setup :verify_on_exit!

  describe "retrieve_token/2" do
    test "returns a token from cache, when available" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:ok, "CACHED-TOKEN"} end)

      assert {:ok, "CACHED-TOKEN"} == CachedTokenService.retrieve_token(@credentials, "target-audience")
    end

    test "returns a fresh token and updates cache if a cached token is not available" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:ok, nil} end)
      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, "target-audience" -> {:ok, "FRESH-TOKEN"} end)
      expect(TokenCacheMock, :set_token_for, fn "target-audience", "FRESH-TOKEN" -> :ok end)

      assert {:ok, "FRESH-TOKEN"} == CachedTokenService.retrieve_token(@credentials, "target-audience")
    end

    test "returns fresh token when cache lookup fails" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:error, :error_description} end)
      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, "target-audience" -> {:ok, "FRESH-TOKEN"} end)
      expect(TokenCacheMock, :set_token_for, fn "target-audience", "FRESH-TOKEN" -> {:error, :error_description} end)

      assert {:ok, "FRESH-TOKEN"} == CachedTokenService.retrieve_token(@credentials, "target-audience")
    end

    test "returns {:error, description} when token retrieval from auth0 fails" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:ok, nil} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, "target-audience" ->
        {:error, :error_description}
      end)

      expect(TokenCacheMock, :set_token_for, 0, fn "target-audience", _ -> :ok end)

      assert {:error, _description} = CachedTokenService.retrieve_token(@credentials, "target-audience")
    end
  end

  describe "refresh_token/3" do
    test "when cached token has been updated by an external entity, simply return the new cached token" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:ok, "NEW-CACHED-TOKEN"} end)

      assert {:ok, "NEW-CACHED-TOKEN"} ==
               CachedTokenService.refresh_token(@credentials, "target-audience", "CURRENT-TOKEN")
    end

    test "when cached token has not changed, update it with a fresh token" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:ok, "CURRENT-TOKEN"} end)
      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, "target-audience" -> {:ok, "FRESH-TOKEN"} end)
      expect(TokenCacheMock, :set_token_for, fn "target-audience", "FRESH-TOKEN" -> :ok end)

      assert {:ok, "FRESH-TOKEN"} ==
               CachedTokenService.refresh_token(@credentials, "target-audience", "CURRENT-TOKEN")
    end

    test "when cache lookup fails, retrieve and return a fresh token" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:error, :error_description} end)
      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, "target-audience" -> {:ok, "FRESH-TOKEN"} end)
      expect(TokenCacheMock, :set_token_for, fn "target-audience", "FRESH-TOKEN" -> {:error, :error_description} end)

      assert {:ok, "FRESH-TOKEN"} ==
               CachedTokenService.refresh_token(@credentials, "target-audience", "CURRENT-TOKEN")
    end
  end
end

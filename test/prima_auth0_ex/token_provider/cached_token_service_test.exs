defmodule PrimaAuth0Ex.TokenProvider.CachedTokenServiceTest do
  use ExUnit.Case, async: true

  import Hammox
  import PrimaAuth0Ex.TestSupport.TimeUtils
  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.TokenProvider.{CachedTokenService, TokenInfo}

  @target_client :default_client
  @target_audience "target-audience"

  @credentials %Auth0Credentials{
    client: @target_client,
    base_url: "base_url",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  setup :verify_on_exit!

  setup do
    saved_env = Application.get_env(:prima_auth0_ex, :token_cache)
    Application.put_env(:prima_auth0_ex, :token_cache, TokenCacheMock)
    on_exit(fn ->
      Application.put_env(:prima_auth0_ex, :token_cache, saved_env)
    end)
  end

  describe "retrieve_token/2" do
    test "returns a token from cache, when available" do
      cached_token = %TokenInfo{jwt: "CACHED-TOKEN", issued_at: one_hour_ago(), expires_at: in_one_hour()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, cached_token} end)

      assert {:ok, cached_token} == CachedTokenService.retrieve_token(@credentials, @target_audience)
    end

    test "returns a fresh token and updates cache if a cached token is not available" do
      fresh_token = %TokenInfo{jwt: "FRESH-TOKEN", issued_at: now(), expires_at: in_two_hours()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, nil} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:ok, fresh_token}
      end)

      expect(TokenCacheMock, :set_token_for, fn @target_client, @target_audience, ^fresh_token -> :ok end)

      assert {:ok, fresh_token} == CachedTokenService.retrieve_token(@credentials, @target_audience)
    end

    test "returns fresh token when cache lookup fails" do
      fresh_token = %TokenInfo{jwt: "FRESH-TOKEN", issued_at: now(), expires_at: in_two_hours()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:error, :error_description} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:ok, fresh_token}
      end)

      expect(TokenCacheMock, :set_token_for, fn @target_client, @target_audience, ^fresh_token ->
        {:error, :error_description}
      end)

      assert {:ok, fresh_token} == CachedTokenService.retrieve_token(@credentials, @target_audience)
    end

    test "returns {:error, description} when token retrieval from auth0 fails" do
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, nil} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:error, :error_description}
      end)

      assert {:error, _description} = CachedTokenService.retrieve_token(@credentials, @target_audience)
    end
  end

  describe "refresh_token/3" do
    test "when cached token has been updated by an external entity, simply return the new cached token" do
      current_token = %TokenInfo{jwt: "CURRENT-TOKEN", issued_at: two_hours_ago(), expires_at: now()}
      new_cached_token = %TokenInfo{jwt: "NEW-CACHED-TOKEN", issued_at: one_hour_ago(), expires_at: in_one_hour()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, new_cached_token} end)

      assert {:ok, new_cached_token} ==
               CachedTokenService.refresh_token(@credentials, @target_audience, current_token, false)
    end

    test "when cached token has not changed, update it with a fresh token" do
      current_token = %TokenInfo{jwt: "CURRENT-TOKEN", issued_at: two_hours_ago(), expires_at: now()}
      fresh_token = %TokenInfo{jwt: "FRESH-TOKEN", issued_at: now(), expires_at: in_two_hours()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, current_token} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:ok, fresh_token}
      end)

      expect(TokenCacheMock, :set_token_for, fn @target_client, @target_audience, ^fresh_token -> :ok end)

      assert {:ok, fresh_token} ==
               CachedTokenService.refresh_token(@credentials, @target_audience, current_token, false)
    end

    test "when cache does not contain any token for the given audience, update it with a fresh one" do
      # this should be very unlikely, as the cache should always be already set at this point

      current_token = %TokenInfo{jwt: "CURRENT-TOKEN", issued_at: two_hours_ago(), expires_at: now()}
      fresh_token = %TokenInfo{jwt: "FRESH-TOKEN", issued_at: now(), expires_at: in_two_hours()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, nil} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:ok, fresh_token}
      end)

      expect(TokenCacheMock, :set_token_for, fn @target_client, @target_audience, ^fresh_token -> :ok end)

      assert {:ok, fresh_token} ==
               CachedTokenService.refresh_token(@credentials, @target_audience, current_token, false)
    end

    test "when cache lookup fails, retrieve and return a fresh token" do
      current_token = %TokenInfo{jwt: "CURRENT-TOKEN", issued_at: two_hours_ago(), expires_at: now()}
      fresh_token = %TokenInfo{jwt: "FRESH-TOKEN", issued_at: now(), expires_at: in_two_hours()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:error, :error_description} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:ok, fresh_token}
      end)

      expect(TokenCacheMock, :set_token_for, fn @target_client, @target_audience, ^fresh_token ->
        {:error, :error_description}
      end)

      assert {:ok, fresh_token} ==
               CachedTokenService.refresh_token(@credentials, @target_audience, current_token, false)
    end

    test "when retrieval from auth0 fails, returns {:error, description}" do
      current_token = %TokenInfo{jwt: "CURRENT-TOKEN", issued_at: two_hours_ago(), expires_at: now()}
      expect(TokenCacheMock, :get_token_for, fn @target_client, @target_audience -> {:ok, current_token} end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:error, :error_description}
      end)

      assert {:error, _} = CachedTokenService.refresh_token(@credentials, @target_audience, current_token, false)
    end

    test "when force_cache_bust is true, refreshes the token in the shared cache regardless of its content" do
      current_token = %TokenInfo{jwt: "CURRENT-TOKEN", issued_at: two_hours_ago(), expires_at: now()}
      fresh_token = %TokenInfo{jwt: "NEW-TOKEN", issued_at: now(), expires_at: in_two_hours()}

      expect(TokenCacheMock, :set_token_for, fn @target_client, @target_audience, ^fresh_token -> :ok end)

      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, @target_audience ->
        {:ok, fresh_token}
      end)

      assert {:ok, fresh_token} ==
               CachedTokenService.refresh_token(@credentials, @target_audience, current_token, true)
    end
  end
end

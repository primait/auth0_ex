# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0-rc.1] - 2021-11-26

### Changed

- Published project to [Hex.pm](https://hex.pm).
- Renamed project to `prima_auth0_ex`. This is a breaking change, and it impacts both configuration and usage of the library.

## [0.2.5] - 2021-11-17

- Bumped version of joken, joken_jwks and telepoison

## [0.2.4] - 2021-10-01

- Bumped some dependencies

## [0.2.3] - 2021-08-18

- Bumped some dependencies

## [0.2.2] - 2021-06-30

- Added `Auth0Ex.refresh_token_for/1`

## [0.2.1] - 2021-04-30

### Added

- Added periodic check on the client to ensure that the signing keys of the tokens are still valid - according to the JWKS server

### Fixed

- Fixed config issue that prevented the redis cache from being enabled in version 0.2.0

## [0.2.0] - 2021-04-15

### Added

- Added support for validation of tokens with multiple audiences
- Added utilities to forge tokens for local development (see `Auth0Ex.LocalToken`)
- Added documentation for use of library to validate permissions in Graphql APIs with Absinthe

### Changed

- Config parameter names have changed - refer to README to see how to update
- Refresh time for a token is now decided upfront as soon as the token is obtained.
- `token_check_interval`, `min_token_duration` and `max_token_duration` are no longer public configurations. It is suggested not to rely on them.

### Fixed

- Fixed validation of permissions for tokens with no `permissions` claim

## [0.1.1] - 2021-03-22

### Fixed

- Fixed compilation error when `:auth0_ex, :server` is not configured in `config.exs`

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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


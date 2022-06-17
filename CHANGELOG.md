# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next]

## [0.4.3] - 2022-06-16

### Changed

- Absinthe plugs uses a map instead of custom struct as context

## [0.4.2] - 2022-06-01

### Fixed

- Fix compilation error when only `:absinthe` dependency is present without `:absinthe_plug`

## [0.4.1] - 2022-06-01

### Added

- New `:redis_ssl_enabled` and `:redis_ssl_allow_wildcard_certificates` options

## [0.4.0] - 2022-05-31

### Added

- New Absinthe plug & middleware to bootstrap authentication
- New telemetry events on token retrieval
- New telemetry pre-defined handler
- New `mix keygen` command to easily generate `cache_encryption_key`

### Fixed

- All errors are logged when caching token on Redis fails

## [0.3.1] - 2022-03-15

### Changed

- [Breaking] When Plug configuration miss the required_permissions field a runtime error will be thrown
  
### Added

- Added `missing_auth_header_log_level` configuration option to control log level when the autorization header is missing.

## [0.3.0] - 2022-01-25

### Added

- Added a warning log to alert of missing configurations at startup.

### Changed

- Token validation configurations are now read at runtime instead of compile time so the library doesn't have to be forcibly recompiled when configurations change.
- Bumped `telepoison` to 1.0

## [0.3.0-rc.1.3] - 2022-01-03

### Changed

- Bumped `jason` to 1.3
- Relaxed version requirements for `jason` and `joken`

## [0.3.0-rc.1.2] - 2021-11-30

### Added

- Added `:ex_doc` dependency

## [0.3.0-rc.1.1] - 2021-11-30

### Fixed

- Fixed package inside mix project

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

[Next]: https://github.com/primait/auth0_ex/compare/0.4.3...HEAD
[0.4.3]: https://github.com/primait/auth0_ex/compare/0.4.2...0.4.3
[0.4.2]: https://github.com/primait/auth0_ex/compare/0.4.1...0.4.2
[0.4.1]: https://github.com/primait/auth0_ex/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/primait/auth0_ex/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/primait/auth0_ex/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/primait/auth0_ex/compare/0.3.0-rc.1.3...0.3.0
[0.3.0-rc.1.3]: https://github.com/primait/auth0_ex/compare/0.3.0-rc.1.2...0.3.0-rc.1.3
[0.3.0-rc.1.2]: https://github.com/primait/auth0_ex/compare/0.3.0-rc.1.1...0.3.0-rc.1.2
[0.3.0-rc.1.1]: https://github.com/primait/auth0_ex/compare/0.3.0-rc.1...0.3.0-rc.1.1
[0.3.0-rc.1]: https://github.com/primait/auth0_ex/compare/0.2.5...0.3.0-rc.1
[0.2.5]: https://github.com/primait/auth0_ex/compare/0.2.4...0.2.5
[0.2.4]: https://github.com/primait/auth0_ex/compare/0.2.3...0.2.4
[0.2.3]: https://github.com/primait/auth0_ex/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/primait/auth0_ex/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/primait/auth0_ex/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/primait/auth0_ex/compare/0.1.1...0.2.0
[0.1.1]: https://github.com/primait/auth0_ex/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/primait/auth0_ex/releases/tag/0.1.0

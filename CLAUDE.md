# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`vmfloaty` is a Ruby CLI gem (`floaty` executable) that wraps Puppet's VMPooler and a few related VM-leasing backends. The gem is installed system-wide; for local development the executable is `bin/floaty`.

## Common commands

```bash
bundle install                                           # install deps
bundle exec rake                                         # default task: rspec
bundle exec rake spec                                    # run all tests
bundle exec rake rubocop                                 # lint
bundle exec rspec spec/vmfloaty/utils_spec.rb            # single file
bundle exec rspec spec/vmfloaty/utils_spec.rb -e 'name'  # single example by description
bundle exec bin/floaty <subcommand> --help               # run the CLI from the working tree
```

CI runs the spec suite against Ruby 2.7, 3.0, 3.1, 3.2 (`.github/workflows/test.yml`); keep changes compatible across that range. Coverage is collected via SimpleCov (HTML + lcov to `coverage/`). HTTP in tests is stubbed with `webmock`.

## Releasing

1. Bump `Vmfloaty::VERSION` in `lib/vmfloaty/version.rb`.
2. Run `./release-prep` — uses Docker to refresh `Gemfile.lock` (in the same Ruby image as `Dockerfile`) and regenerate `CHANGELOG.md` via `github_changelog_generator` (requires `CHANGELOG_GITHUB_TOKEN`).
3. PR to `main` with the `maintenance` label.
4. After merge, manually run the `release.yml` workflow in the GitHub Actions UI — that publishes the GitHub release, RubyGems gem, and GHCR image.

## Architecture

The CLI is one big Commander program in `lib/vmfloaty.rb` — every subcommand (`get`, `delete`, `list`, `modify`, `query`, `revert`, `service`, `snapshot`, `ssh`, `status`, `summary`, `token`, `completion`) is a `command :foo do |c| … end` block in `Vmfloaty#run`. New subcommands go there.

The key abstraction is `Service` (`lib/vmfloaty/service.rb`):

- Each command builds `Service.new(options, config)`.
- `Service` resolves the per-invocation config via `Utils.get_service_config` (CLI flags > selected service from `~/.vmfloaty.yml` > top-level fallbacks) and picks a **backend class** from `config['type']` via `Utils.get_service_object`.
- Backend classes are `Pooler` (VMPooler, `lib/vmfloaty/pooler.rb`), `ABS` (`abs.rb`), and `NonstandardPooler` (`nonstandard_pooler.rb`). They expose **class methods** (`retrieve`, `list`, `query`, `modify`, `delete`, `status`, `summary`, `snapshot`, `revert`, `disk`, `wait_for_request`, …); `Service` forwards via `method_missing` to whichever backend is active.
- `Service#maybe_use_vmpooler` — several operations (`modify`, `summary`, `snapshot`, `revert`, `disk`) don't exist on ABS. When the active backend is `ABS`, `Service` transparently swaps itself to `Pooler` using the `vmpooler_fallback` service named in the ABS config. If you add a backend-specific method, decide whether it needs this fallback.

Auth is split: `Auth` (`auth.rb`) owns token get/delete/status against VMPooler-style endpoints; `Service` calls into `Auth` and caches the token on `@config`. ABS does not have its own token endpoint and uses the fallback VMPooler for token operations.

`Utils` (`utils.rb`) is the shared toolbox: argument parsing (`generate_os_hash` parses `os=N` CLI args), response normalization (`standardize_hostnames` reconciles the three different response shapes from VMPooler v1, VMPooler v2, NonstandardPooler, and ABS — see the comment block at the top of that method), pretty-printing (`format_host_output`, `pretty_print_status`, `pretty_print_hosts`), and config resolution. Backend response shapes diverge a lot; when adding a backend or changing a command's output, update `standardize_hostnames` and the relevant pretty-printer together.

`Http.get_conn` (`http.rb`) is the single Faraday entry point — every backend uses it so verbose logging behaves consistently. `FloatyLogger` (`logger.rb`) is the project's logger; prefer it over `puts`/`STDERR` for status/error output (data destined for stdout consumption stays on `puts`/`JSON.pretty_generate`).

User config lives at `~/.vmfloaty.yml`. It can be a single flat service or a map of named services under `services:` (with top-level keys as fallback defaults). `floaty service types` and `floaty service examples` are the source of truth for valid `type:` values and example configs — keep them updated when adding a backend.

## Testing notes

- `spec/spec_helper.rb` defines `MockOptions` (a `Commander::Command::Options` subclass that accepts a hash) and a `get_headers` helper that constructs the exact headers Faraday sends — use them when stubbing requests with webmock.
- Specs are organized one file per `lib/vmfloaty/*.rb`; mirror that when adding a new module.

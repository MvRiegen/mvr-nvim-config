# AI Coding Agent Instructions

Personal Neovim config (Neovim 0.12+, lazy.nvim). The repo root is the config directory (`~/.config/nvim`). See `README.md` for requirements and install steps.

## Commands

```sh
make all     # lint + luals + test
make test    # plenary-busted over tests/unit using tests/minimal_init.lua
make lint    # luacheck lua/ tests/
make luals   # lua-language-server --check (Warning level, .luarc.json)
```

- By default the Makefile runs everything inside the `Dockerfile.ci` image (built as `$(CI_IMAGE)`, default `nvim-linux`, with the repo mounted at `/work`). No local luarocks/MSVC/LuaLS is needed, which matters on Windows where building luacheck is painful. `make test` clones plenary (pinned to `PLENARY_REV`) inside the container with an isolated HOME/XDG setup.
- On Windows, `make lint` and `make luals` only work through Docker (the default). `make USE_DOCKER=0 test` is fine locally.
- `make USE_DOCKER=0 <target>` runs with local tools instead. Then `luacheck` / `lua-language-server` are resolved from PATH, then `~/.luarocks/bin`, then the Mason bin dir; override with `LUACHECK=` / `LUALS=` / `NVIM=`, and plenary must be at `$PLENARY_PATH` or `stdpath("data")/lazy/plenary.nvim`.
- Run a single spec (local tools): `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/unit/tooling_spec.lua"`
- Formatting: stylua (`.stylua.toml`: 120 cols, 2-space indent, double quotes).
- CI (`Jenkinsfile`) does not use the Makefile. It runs the same tools directly inside `Dockerfile.ci` (lint, LuaLS, unit tests), then a headless startup check on Linux amd64/arm64 and Windows. Keep the Makefile docker commands and the Jenkinsfile stages in sync when changing either.

## Architecture

- `init.lua` requires `config.lazy`, `config.keymaps`, `config.telescope`, then sets UI options and diagnostics inline.
- `lua/config/lazy.lua` bootstraps lazy.nvim and imports every spec in `lua/plugins/` (one file per plugin, each returns a lazy spec). `lazy-lock.json` pins versions, and Renovate updates it.
- `lua/config/*.lua` holds plain helper modules that plugin specs consume. Keep logic here, not in the specs, so it can be unit tested:
  - `tooling.lua` is the single source of truth for formatters (`formatters_by_ft`), linters (`linters_by_ft`), and Mason tools. `filter_mason_tools` drops tools unsupported on arm64, FreeBSD, or Windows without MSVC `cl`. `conform.lua`, `nvim-lint.lua`, `mason-tool-installer.lua`, and `mason.lua` all read from it.
  - `mason_sync.lua`, `session_manager.lua`, and `startup.lua` (clean-session flags `vim.g.no_session_autoload` / `NVIM_NO_SESSION`) support the matching plugin specs.
- `lua/plugins/platform-tools.lua` installs tools that Mason can't provide on some platforms (for example aarch64), exposed via `:PlatformToolsInstallSync`.
- Per-project overrides go through neoconf.nvim.

## Tests

- Specs live in `tests/unit/*_spec.lua`. They load modules with `dofile(root .. "/lua/...")` or `require`, so cover new `config/` logic by stubbing `vim.*` and injecting inputs. Plugin specs under `lua/plugins/` are exercised the same way.
- `tests/plenary_to_junit.lua` and `tests/checkstyle_from_log.lua` convert output for Jenkins reports.
- `.luacheckrc` declares the globals `vim`, `describe`, and `it`, and ignores `_*` names.

## Notes

- Platform-specific behavior (Windows, arm64, FreeBSD) is handled by guards in `tooling.lua` and the plugin specs. Keep new tool additions consistent with those guards, and update `README.md` if the optional requirements change.

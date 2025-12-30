# mvr-nvim-config

Personal Neovim configuration with a clean, practical LSP/format/lint setup.

## Highlights

- LSP with Mason (pyright, clangd, lemminx, bashls, etc.)
- Formatter/Linter orchestration via Conform + nvim-lint
- Platform helpers for aarch64/amd64
- Project overrides with neoconf.nvim

## Requirements

- Neovim 0.11+
- git
- Optional:
  - node/npm (for some LSPs and tools)
  - `shfmt`, `shellcheck` (shell formatting/lint)
  - `libxml2` (xmllint for XML formatting)

## Install

```sh
git clone https://github.com/MvRiegen/mvr-nvim-config ~/.config/nvim
```

Inside Neovim:

```vim
:Lazy sync
:MasonToolsInstallSync
:TSUpdate
```

## Headless update script

```sh
/usr/bin/nvim --headless \
  "+Lazy! sync" \
  "+MasonUpdate" \
  "+MasonToolsInstallSync" \
  "+MasonLspInstallSync" \
  "+PlatformToolsInstallSync" \
  "+TSUpdate" \
  "+qa"
```

## Project overrides (neoconf)

Create `.neoconf.json` in a project root:

```json
{
  "lspconfig": {
    "pyright": {
      "settings": {
        "python.analysis.typeCheckingMode": "basic"
      }
    }
  }
}
```

## License

MIT

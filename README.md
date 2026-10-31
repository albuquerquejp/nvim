# nvim

My Neovim config, for macOS, Ubuntu and Ubuntu on WSL.

## Install

```sh
git clone git@github.com:albuquerquejp/nvim.git ~/.config/nvim
~/.config/nvim/install.sh
```

If you clone it somewhere else, `install.sh` symlinks `~/.config/nvim` to the
clone and moves any existing config to `~/.config/nvim.bak.<timestamp>`.

The script is safe to re-run. It installs:

| What | Version | Where |
|---|---|---|
| Neovim | 0.11.5 (pinned, checksum-verified) | `~/.local/opt/nvim-v0.11.5`, linked as `~/.local/bin/nvim` |
| Node.js for Mason/LSPs | 24.22.2 (pinned) | `~/.local/share/nvim/toolchain/`, on Neovim's PATH only |
| System packages | apt / brew | ripgrep, fd, make + C compiler, python3-venv, unzip, clipboard tool |
| Nerd Font | JetBrainsMono Nerd Font Mono 3.5.1 | user font dir (on WSL also installed on Windows) |
| Plugins | as pinned in `lazy-lock.json` | `~/.local/share/nvim/lazy` |
| LSP servers / formatters | via Mason | `~/.local/share/nvim/mason` |
| Treesitter parsers | | `~/.local/share/nvim/lazy/nvim-treesitter/parser` |

Options: `--no-system-packages`, `--no-fonts`, `--no-plugins` (see `./install.sh --help`).

Requirements: `curl` and `git`. On macOS also the Xcode Command Line Tools and
Homebrew. On Ubuntu, `sudo` for the apt packages.

After installing, set your terminal font to **JetBrainsMono Nerd Font Mono**.
`~/.local/bin` must come before any other Neovim on your `PATH`; the script
warns you if it doesn't.

## Upgrading

- **Plugins:** run `:Lazy update`, test, then commit `lazy-lock.json`. Other
  machines pick the change up with `git pull && ./install.sh`, which runs
  `:Lazy restore` against the lockfile.
- **Neovim / Node / font:** change the version at the top of `install.sh`,
  update the matching SHA-256 in `pinned_sha256`, and re-run the script.
  Older versions stay in `~/.local/opt` until you delete them.

## Theme

Everforest light (soft) by default; `<leader>tt` toggles to tokyonight-moon.

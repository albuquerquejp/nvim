#!/usr/bin/env bash
# Bootstrap this Neovim config on macOS, Ubuntu or Ubuntu on WSL.
#
#   git clone git@github.com:albuquerquejp/nvim.git ~/.config/nvim
#   ~/.config/nvim/install.sh
set -euo pipefail

# ---- Pinned versions (bump these together, then re-run) ---------------------
NVIM_VERSION="0.11.5"
NODE_VERSION="24.22.2" # used only by Neovim (Mason installs npm-based LSPs with it)
NERD_FONTS_VERSION="3.5.1"
WIN32YANK_VERSION="0.1.1"

pinned_sha256() {
	case "$1" in
	nvim-linux-x86_64.tar.gz) echo b2f91117be5b5ea39edd7297156dc2a4a8df4add6c95a90809a8df19e7ab6f52 ;;
	nvim-linux-arm64.tar.gz) echo ea4f9a31b11cc1477ff014aebb7b207684e7280f94ffa97abdab6cacd9b98519 ;;
	nvim-macos-arm64.tar.gz) echo 79143d3b408f7034f90b7cf59af2276de09ef8a4c2f1a28e4c99581b249d3107 ;;
	nvim-macos-x86_64.tar.gz) echo 6612760a7037ca2518e456908baf5e43101fa79819d18979fc4d4e8441d9dfa5 ;;
	node-v24.22.2-linux-x64.tar.xz) echo 48cc0e21e048790e54c0cf5749c2725005313d652651c40b7a21feb9697aaf75 ;;
	node-v24.22.2-linux-arm64.tar.xz) echo eb187837a2230d4047161ac0be008584e16b46f726e9c9490ee35dc6b17d9ba8 ;;
	node-v24.22.2-darwin-arm64.tar.xz) echo 1f5ac075be50bed4780ea3be19a007fda95ea4d527d28d76d0b91de47d915115 ;;
	node-v24.22.2-darwin-x64.tar.xz) echo 6965578fd823e72c1b5387f5ab84cb25368f886e02eb8779e6f0fce6b91c27b7 ;;
	JetBrainsMono.tar.xz) echo 04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf ;;
	win32yank-x64.zip) echo 247c9a05b94387a884b49d3db13f806b1677dfc38020f955f719be6902260cd6 ;;
	esac
}

# ---- Paths ------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"
TOOLCHAIN_DIR="$DATA_DIR/toolchain" # init.lua puts $TOOLCHAIN_DIR/node/bin on Neovim's PATH
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DO_SYSTEM=1
DO_FONTS=1
DO_PLUGINS=1

usage() {
	cat <<EOF
Usage: $(basename "$0") [options]

Installs Neovim $NVIM_VERSION, its system dependencies, a Nerd Font and all
plugins, LSP servers and treesitter parsers used by this config.

Options:
  --no-system-packages  skip apt/brew packages (ripgrep, fd, compilers, ...)
  --no-fonts            skip the JetBrainsMono Nerd Font
  --no-plugins          skip installing plugins, LSP servers and parsers
  -h, --help            show this help
EOF
}

for arg in "$@"; do
	case "$arg" in
	--no-system-packages) DO_SYSTEM=0 ;;
	--no-fonts) DO_FONTS=0 ;;
	--no-plugins) DO_PLUGINS=0 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $arg" >&2
		usage >&2
		exit 1
		;;
	esac
done

# ---- Helpers ----------------------------------------------------------------
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m    ! %s\033[0m\n' "$*"; }
die() {
	printf '\033[1;31m    x %s\033[0m\n' "$*" >&2
	exit 1
}

sha256() {
	if command -v sha256sum >/dev/null; then
		sha256sum "$1" | cut -d' ' -f1
	else
		shasum -a 256 "$1" | cut -d' ' -f1
	fi
}

# download <url> <dest>: fetch a pinned file and check it against pinned_sha256
download() {
	local url="$1" dest="$2" name expected actual
	name="$(basename "$url")"
	expected="$(pinned_sha256 "$name")"
	[[ -n "$expected" ]] || die "No pinned checksum for $name"
	info "Downloading $name"
	curl -fsSL --retry 3 -o "$dest" "$url"
	actual="$(sha256 "$dest")"
	[[ "$actual" == "$expected" ]] || die "Checksum mismatch for $name (expected $expected, got $actual)"
}

# ---- Platform detection -----------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_WSL=0
case "$OS" in
Linux)
	PLATFORM="linux"
	grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1
	case "$ARCH" in
	x86_64) NVIM_ARCH="x86_64" NODE_ARCH="x64" ;;
	aarch64 | arm64) NVIM_ARCH="arm64" NODE_ARCH="arm64" ;;
	*) die "Unsupported architecture: $ARCH" ;;
	esac
	;;
Darwin)
	PLATFORM="macos"
	case "$ARCH" in
	x86_64) NVIM_ARCH="x86_64" NODE_ARCH="x64" ;;
	arm64) NVIM_ARCH="arm64" NODE_ARCH="arm64" ;;
	*) die "Unsupported architecture: $ARCH" ;;
	esac
	;;
*) die "Unsupported OS: $OS (this script supports macOS and Linux/WSL)" ;;
esac

desc="$PLATFORM/$ARCH"
[[ $IS_WSL -eq 1 ]] && desc="$desc (WSL)"
step "Setting up Neovim $NVIM_VERSION on $desc"
mkdir -p "$BIN_DIR" "$OPT_DIR" "$TOOLCHAIN_DIR"

# ---- 1. System packages -----------------------------------------------------
install_system_packages() {
	step "System packages"
	if [[ "$PLATFORM" == "macos" ]]; then
		xcode-select -p >/dev/null 2>&1 || die "Install the Xcode Command Line Tools first: xcode-select --install"
		command -v brew >/dev/null || die "Install Homebrew first: https://brew.sh"
		# git, curl, make, cc, unzip, tar and python3 come with the Command Line Tools
		brew install ripgrep fd
	else
		command -v apt-get >/dev/null || die "Only apt-based distros (Ubuntu/Debian) are supported; re-run with --no-system-packages"
		local pkgs=(
			git curl unzip tar gzip xz-utils # downloads and Mason installers
			build-essential                  # make + cc for treesitter parsers, telescope-fzf-native, LuaSnip
			ripgrep fd-find                  # Telescope live_grep / find_files
			python3 python3-venv             # Mason's pip-based tools (ruff)
			fontconfig                       # fc-cache for the Nerd Font
		)
		# Outside WSL Neovim needs a clipboard tool for X11 or Wayland
		[[ $IS_WSL -eq 0 ]] && pkgs+=(xclip wl-clipboard)
		sudo apt-get update -qq
		sudo apt-get install -y -qq "${pkgs[@]}"
		# Ubuntu ships fd as `fdfind`
		if ! command -v fd >/dev/null && command -v fdfind >/dev/null; then
			ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
		fi
	fi
}

# ---- 2. Neovim --------------------------------------------------------------
install_neovim() {
	step "Neovim $NVIM_VERSION"
	local target="$OPT_DIR/nvim-v$NVIM_VERSION"
	if [[ -x "$target/bin/nvim" ]]; then
		info "Already installed in $target"
	else
		local asset="nvim-$PLATFORM-$NVIM_ARCH.tar.gz"
		download "https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/$asset" "$TMP_DIR/$asset"
		mkdir -p "$TMP_DIR/nvim" && tar -xzf "$TMP_DIR/$asset" -C "$TMP_DIR/nvim" --strip-components=1
		[[ "$PLATFORM" == "macos" ]] && xattr -cr "$TMP_DIR/nvim" 2>/dev/null || true # avoid Gatekeeper prompts
		rm -rf "$target" && mv "$TMP_DIR/nvim" "$target"
		info "Installed in $target"
	fi
	ln -sfn "$target/bin/nvim" "$BIN_DIR/nvim"
	info "Linked $BIN_DIR/nvim"
}

# ---- 3. Node.js for Mason (private to Neovim) -------------------------------
install_node() {
	step "Node.js $NODE_VERSION (only on Neovim's PATH, for Mason/LSPs)"
	local target="$TOOLCHAIN_DIR/node-v$NODE_VERSION"
	if [[ -x "$target/bin/node" ]]; then
		info "Already installed in $target"
	else
		local os_name="linux"
		[[ "$PLATFORM" == "macos" ]] && os_name="darwin"
		local asset="node-v$NODE_VERSION-$os_name-$NODE_ARCH.tar.xz"
		download "https://nodejs.org/dist/v$NODE_VERSION/$asset" "$TMP_DIR/$asset"
		mkdir -p "$TMP_DIR/node" && tar -xJf "$TMP_DIR/$asset" -C "$TMP_DIR/node" --strip-components=1
		rm -rf "$target" && mv "$TMP_DIR/node" "$target"
		info "Installed in $target"
	fi
	ln -sfn "$target" "$TOOLCHAIN_DIR/node"
}

# ---- 4. Clipboard on WSL ----------------------------------------------------
install_win32yank() {
	command -v win32yank.exe >/dev/null && return
	step "win32yank $WIN32YANK_VERSION (WSL clipboard)"
	download "https://github.com/equalsraf/win32yank/releases/download/v$WIN32YANK_VERSION/win32yank-x64.zip" "$TMP_DIR/win32yank.zip"
	unzip -o -q "$TMP_DIR/win32yank.zip" win32yank.exe -d "$BIN_DIR"
	chmod +x "$BIN_DIR/win32yank.exe"
	info "Installed $BIN_DIR/win32yank.exe"
}

# ---- 5. Nerd Font -----------------------------------------------------------
# blink.cmp is set to nerd_font_variant = "mono", so install the "Nerd Font Mono" family.
FONT_FAMILY="JetBrainsMono Nerd Font Mono"
FONT_FILES=(JetBrainsMonoNerdFontMono-{Regular,Bold,Italic,BoldItalic}.ttf)

install_font() {
	step "$FONT_FAMILY $NERD_FONTS_VERSION"
	local font_dir
	case "$PLATFORM" in
	macos) font_dir="$HOME/Library/Fonts" ;;
	linux) font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont" ;;
	esac

	if [[ -f "$font_dir/${FONT_FILES[0]}" && $IS_WSL -eq 0 ]]; then
		info "Already installed in $font_dir"
		return
	fi

	download "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_FONTS_VERSION/JetBrainsMono.tar.xz" "$TMP_DIR/JetBrainsMono.tar.xz"
	mkdir -p "$TMP_DIR/font" && tar -xJf "$TMP_DIR/JetBrainsMono.tar.xz" -C "$TMP_DIR/font" "${FONT_FILES[@]}"

	mkdir -p "$font_dir"
	cp "${FONT_FILES[@]/#/$TMP_DIR/font/}" "$font_dir/"
	command -v fc-cache >/dev/null && fc-cache -f "$font_dir" >/dev/null
	info "Installed in $font_dir"

	# On WSL the terminal is a Windows app, so the font must be installed on Windows too
	[[ $IS_WSL -eq 1 ]] && install_font_windows "$TMP_DIR/font"
}

install_font_windows() {
	command -v powershell.exe >/dev/null || {
		warn "powershell.exe not found; install the font on Windows by hand"
		return
	}
	local ps1="$TMP_DIR/install-font.ps1"
	# Per-user install: no admin rights needed
	cat >"$ps1" <<'EOF'
param([string]$Source)
$dir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ChildItem -Path $Source -Filter *.ttf | ForEach-Object {
    $dest = Join-Path $dir $_.Name
    if (-not (Test-Path $dest)) { Copy-Item -Path $_.FullName -Destination $dest }
    $style = $_.BaseName -replace '^JetBrainsMonoNerdFontMono-', ''
    New-ItemProperty -Path $reg -Name "JetBrainsMono Nerd Font Mono $style (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
}
EOF
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps1")" -Source "$(wslpath -w "$1")"
	info "Installed on Windows for the current user (select it in Windows Terminal)"
}

# ---- 6. Link the config -----------------------------------------------------
link_config() {
	step "Config"
	if [[ "$(cd "$CONFIG_DIR" 2>/dev/null && pwd -P)" == "$(cd "$REPO_DIR" && pwd -P)" ]]; then
		info "$CONFIG_DIR is this repo"
		return
	fi
	if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
		local backup
		backup="$CONFIG_DIR.bak.$(date +%Y%m%d%H%M%S)"
		mv "$CONFIG_DIR" "$backup"
		warn "Moved the existing config to $backup"
	fi
	mkdir -p "$(dirname "$CONFIG_DIR")"
	ln -s "$REPO_DIR" "$CONFIG_DIR"
	info "Linked $CONFIG_DIR -> $REPO_DIR"
}

# ---- 7. Plugins, LSP servers, parsers ---------------------------------------
install_plugins() {
	local nvim="$BIN_DIR/nvim"
	step "Plugins (pinned by lazy-lock.json)"
	"$nvim" --headless "+Lazy! restore" +qa
	step "LSP servers and formatters (Mason)"
	"$nvim" --headless "+MasonToolsInstallSync" +qa
	step "Treesitter parsers"
	"$nvim" --headless "+TSUpdateSync" +qa
}

# ---- Run --------------------------------------------------------------------
[[ $DO_SYSTEM -eq 1 ]] && install_system_packages
install_neovim
install_node
[[ $IS_WSL -eq 1 ]] && install_win32yank
[[ $DO_FONTS -eq 1 ]] && install_font
link_config
[[ $DO_PLUGINS -eq 1 ]] && install_plugins

step "Done"
resolved="$(command -v nvim || true)"
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
	warn "$BIN_DIR is not on your PATH. Add this to your shell rc file:"
	warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
elif [[ "$resolved" != "$BIN_DIR/nvim" ]]; then
	warn "\`nvim\` resolves to $resolved, which comes before $BIN_DIR on your PATH."
	warn "Remove that install, or move $BIN_DIR earlier in PATH."
else
	info "$("$BIN_DIR/nvim" --version | head -1) is ready"
fi
[[ $DO_FONTS -eq 1 ]] && info "Set your terminal font to \"$FONT_FAMILY\"."
exit 0

#!/usr/bin/env bash
set -euo pipefail

PREFIX="/usr/local"
BIN_DIR=""
NETMAN_HOME=""
BASH_COMPLETION_DIR="/etc/bash_completion.d"
ZSH_COMPLETION_DIR=""
TARGET_USER="${SUDO_USER:-$(id -un)}"
SKIP_PASSWORDLESS=0
INSTALL_BASH_COMPLETION=1
INSTALL_ZSH_COMPLETION=1

usage() {
  cat <<USAGE
Usage:
  ./install.sh [options]

Options:
  --prefix <dir>               Install prefix (default: /usr/local)
  --bin-dir <dir>              Bin directory (default: <prefix>/bin)
  --home <dir>                 Netman home directory (default: <prefix>/share/netman)
  --user <name>                User for passwordless setup (default: current user)
  --skip-passwordless          Do not run setup-passwordless-netman.sh
  --skip-completions           Do not install shell completion files
  --no-bash-completion         Do not install bash completion file
  --no-zsh-completion          Do not install zsh completion file
  -h, --help                   Show this help

Examples:
  sudo ./install.sh
  sudo ./install.sh --user elie
  ./install.sh --prefix "$HOME/.local" --skip-passwordless
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    --home)
      NETMAN_HOME="$2"
      shift 2
      ;;
    --user)
      TARGET_USER="$2"
      shift 2
      ;;
    --skip-passwordless)
      SKIP_PASSWORDLESS=1
      shift
      ;;
    --skip-completions)
      INSTALL_BASH_COMPLETION=0
      INSTALL_ZSH_COMPLETION=0
      shift
      ;;
    --no-bash-completion)
      INSTALL_BASH_COMPLETION=0
      shift
      ;;
    --no-zsh-completion)
      INSTALL_ZSH_COMPLETION=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for required in netman setup-passwordless-netman.sh README.md completions/netman.bash completions/_netman profiles; do
  if [[ ! -e "$SCRIPT_DIR/$required" ]]; then
    echo "Missing required path: $SCRIPT_DIR/$required" >&2
    echo "Run this script from a netman project/dist folder." >&2
    exit 1
  fi
done

if [[ -z "$BIN_DIR" ]]; then
  BIN_DIR="$PREFIX/bin"
fi
if [[ -z "$NETMAN_HOME" ]]; then
  NETMAN_HOME="$PREFIX/share/netman"
fi
if [[ -z "$ZSH_COMPLETION_DIR" ]]; then
  ZSH_COMPLETION_DIR="$PREFIX/share/zsh/site-functions"
fi

mkdir -p "$NETMAN_HOME" "$NETMAN_HOME/profiles" "$NETMAN_HOME/completions" "$NETMAN_HOME/backups" "$BIN_DIR"

install -m 755 "$SCRIPT_DIR/netman" "$NETMAN_HOME/netman"
install -m 755 "$SCRIPT_DIR/setup-passwordless-netman.sh" "$NETMAN_HOME/setup-passwordless-netman.sh"
install -m 644 "$SCRIPT_DIR/README.md" "$NETMAN_HOME/README.md"
install -m 644 "$SCRIPT_DIR/completions/netman.bash" "$NETMAN_HOME/completions/netman.bash"
install -m 644 "$SCRIPT_DIR/completions/_netman" "$NETMAN_HOME/completions/_netman"

find "$SCRIPT_DIR/profiles" -mindepth 1 -maxdepth 1 -type f -exec install -m 644 -t "$NETMAN_HOME/profiles" {} +

cat > "$BIN_DIR/netman" <<EOF_WRAPPER
#!/usr/bin/env bash
set -euo pipefail
export NETMAN_HOME="$NETMAN_HOME"
exec "\$NETMAN_HOME/netman" "\$@"
EOF_WRAPPER
chmod 755 "$BIN_DIR/netman"

if [[ "$INSTALL_BASH_COMPLETION" -eq 1 ]]; then
  if [[ -d "$BASH_COMPLETION_DIR" ]]; then
    install -m 644 "$SCRIPT_DIR/completions/netman.bash" "$BASH_COMPLETION_DIR/netman"
  else
    echo "Skipping bash completion (directory missing: $BASH_COMPLETION_DIR)"
  fi
fi

if [[ "$INSTALL_ZSH_COMPLETION" -eq 1 ]]; then
  mkdir -p "$ZSH_COMPLETION_DIR"
  install -m 644 "$SCRIPT_DIR/completions/_netman" "$ZSH_COMPLETION_DIR/_netman"
fi

if [[ "$SKIP_PASSWORDLESS" -eq 0 ]]; then
  if [[ "$EUID" -ne 0 ]]; then
    echo "Skipping passwordless setup (not root). Re-run with sudo or use --skip-passwordless." >&2
  else
    NETMAN_HOME="$NETMAN_HOME" "$NETMAN_HOME/setup-passwordless-netman.sh" "$TARGET_USER"
  fi
fi

echo "Installed netman"
echo "  bin:  $BIN_DIR/netman"
echo "  home: $NETMAN_HOME"
echo ""
echo "Try:"
echo "  netman --help"
echo "  netman list"
echo "  netman --test set <profile>"

#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root once, e.g.: sudo ./setup-passwordless-netman.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETMAN_HOME="${NETMAN_HOME:-$SCRIPT_DIR}"
CONFIG_DIR="$NETMAN_HOME/profiles"
APPLIER_PATH="/usr/local/sbin/netman-apply"

TARGET_USER="${SUDO_USER:-${1:-}}"
if [[ -z "$TARGET_USER" ]]; then
  echo "Could not determine target user." >&2
  echo "Usage: sudo ./setup-passwordless-netman.sh <username>" >&2
  exit 1
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "User not found: $TARGET_USER" >&2
  exit 1
fi

if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "Missing config directory: $CONFIG_DIR" >&2
  exit 1
fi

BACKUP_DIR="$NETMAN_HOME/backups"
BACKUP_LIMIT=5
SUDOERS_PATH="/etc/sudoers.d/netman-${TARGET_USER}"

cat > "$APPLIER_PATH" <<EOF_APPLIER
#!/usr/bin/env bash
set -euo pipefail

ACTION="\${1:-}"
PROFILE="\${2:-}"
CONFIG_DIR="$CONFIG_DIR"
BACKUP_DIR="$BACKUP_DIR"
BACKUP_LIMIT="$BACKUP_LIMIT"
TARGET_USER="$TARGET_USER"

mkdir -p "\$BACKUP_DIR"
chown root:root "\$BACKUP_DIR"
chmod 0755 "\$BACKUP_DIR"

case "\$ACTION" in
  apply)
    case "\$PROFILE" in
      ""|*[^A-Za-z0-9._-]*)
        echo "Invalid profile name: \$PROFILE" >&2
        exit 2
        ;;
    esac

    SOURCE="\$CONFIG_DIR/\$PROFILE"
    if [[ ! -f "\$SOURCE" ]]; then
      echo "Profile not found: \$PROFILE" >&2
      exit 3
    fi

    if [[ -f /etc/resolv.conf ]]; then
      STAMP="\$(date +%Y%m%d-%H%M%S)-\$\$"
      install -m 0600 /etc/resolv.conf "\$BACKUP_DIR/\${TARGET_USER}-live-\${STAMP}.bak"
      COUNT=0
      while IFS= read -r OLD; do
        COUNT=\$((COUNT + 1))
        if [[ "\$COUNT" -gt "\$BACKUP_LIMIT" ]]; then
          rm -f "\$OLD"
        fi
      done < <(ls -1t "\$BACKUP_DIR/\${TARGET_USER}-live-"*.bak 2>/dev/null || true)
    fi

    install -m 0644 "\$SOURCE" /etc/resolv.conf
    ;;
  rollback)
    LATEST="\$(ls -1t "\$BACKUP_DIR/\${TARGET_USER}-live-"*.bak 2>/dev/null | head -n1 || true)"
    if [[ -z "\$LATEST" ]]; then
      echo "No backup found" >&2
      exit 4
    fi
    install -m 0644 "\$LATEST" /etc/resolv.conf
    ;;
  *)
    echo "Usage: netman-apply {apply <profile>|rollback}" >&2
    exit 1
    ;;
esac
EOF_APPLIER

chown root:root "$APPLIER_PATH"
chmod 0755 "$APPLIER_PATH"

printf '%s ALL=(root) NOPASSWD: %s *\n' "$TARGET_USER" "$APPLIER_PATH" > "$SUDOERS_PATH"
chmod 0440 "$SUDOERS_PATH"

visudo -cf "$SUDOERS_PATH" >/dev/null

echo "Installed passwordless netman helper for user '$TARGET_USER'."
echo "Commands enabled: apply <profile>, rollback"
echo "You can now run: netman set <profile>  and  netman rollback"

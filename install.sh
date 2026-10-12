#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export PYTHONDONTWRITEBYTECODE=1
if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' 'INSTALLER: BLOCKED_MISSING_DEPENDENCIES' 'python3 ausente. Arch: sudo pacman -S --needed python' >&2
    exit 1
fi
exec python3 "$project_dir/scripts/install-session" "$@"

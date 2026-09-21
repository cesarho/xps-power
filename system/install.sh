#!/bin/bash

# Installs the root-owned helper and its polkit action.
#
#   system/install.sh              install / update
#   system/install.sh --uninstall  remove
#
# Run it as your regular user; it asks for your password through sudo.
#
# Root never reads a file from this checkout, which is writable by your
# user. Instead root downloads system/ from GitHub, pinned to the commit
# this checkout is on, so the installed helper matches the widget and only
# code that was pushed to the repo can end up running as root. The commit
# hash already pins the content, so no separate checksum file is needed.
# Re-run it after `omarchy plugin update` if system/ changed.

set -euo pipefail
PATH=/usr/bin:/bin

repo=cesarho/xps-power
libexec_dir=/usr/local/libexec/xps-power
helper=$libexec_dir/xps-power-battery-set
policy=/usr/share/polkit-1/actions/com.cesarho.xps-power.policy

fail() { echo "install.sh: $*" >&2; exit 1; }

(( EUID != 0 )) || fail "run it as your regular user, not with sudo"

if [[ ${1:-} == --uninstall ]]; then
  sudo rm -f "$helper" "$policy"
  sudo rmdir "$libexec_dir" 2>/dev/null || true
  echo "Removed."
  exit 0
fi

[[ $# == 0 ]] || fail "usage: $0 [--uninstall]"

here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
commit=$(git -C "$here" rev-parse HEAD) \
  || fail "not a git checkout; install with: omarchy plugin add https://github.com/$repo.git --enable"
[[ $commit =~ ^[0-9a-f]{40}$ ]] || fail "unexpected git HEAD: $commit"

# Downloads as root into a temporary name next to the target, then renames
# it into place, so a failed download never leaves a partial file behind.
fetch() {
  local src=$1 dest=$2 mode=$3
  sudo curl -fsS --proto '=https' --max-time 30 \
    -o "$dest.new" "https://raw.githubusercontent.com/$repo/$commit/$src" \
    || { sudo rm -f "$dest.new"; fail "could not download $src at $commit (no network, or commit not pushed?)"; }
  sudo chown root:root "$dest.new"
  sudo chmod "$mode" "$dest.new"
  sudo mv -f "$dest.new" "$dest"
}

sudo install -d -o root -g root -m 0755 "$libexec_dir"
fetch system/xps-power-battery-set "$helper" 0755
fetch system/com.cesarho.xps-power.policy "$policy" 0644

echo "Installed $helper and $policy from $repo@${commit:0:7}"

#!/bin/bash

# One-time install of the root-owned helper and its polkit action.
#
#   sudo system/install.sh              install / update
#   sudo system/install.sh --uninstall  remove
#
# Run this yourself from a terminal, after reading the files it installs. The
# widget deliberately never installs or updates these files itself, since
# doing so from the user-writable plugin folder would reopen the hole this
# split exists to close. Re-run it after `omarchy plugin update` if
# system/ changed.

set -euo pipefail

libexec_dir=/usr/local/libexec/xps-power
policy=/usr/share/polkit-1/actions/com.cesarho.xps-power.policy

(( EUID == 0 )) || { echo "Run as root: sudo $0 $*" >&2; exit 1; }

if [[ ${1:-} == --uninstall ]]; then
  rm -f "$libexec_dir/xps-power-battery-set" "$policy"
  rmdir "$libexec_dir" 2>/dev/null || true
  echo "Removed."
  exit 0
fi

[[ $# == 0 ]] || { echo "Usage: sudo $0 [--uninstall]" >&2; exit 1; }

src=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

install -d -o root -g root -m 0755 "$libexec_dir"
install -o root -g root -m 0755 "$src/xps-power-battery-set" "$libexec_dir/xps-power-battery-set"
install -o root -g root -m 0644 "$src/com.cesarho.xps-power.policy" "$policy"

echo "Installed $libexec_dir/xps-power-battery-set and $policy"

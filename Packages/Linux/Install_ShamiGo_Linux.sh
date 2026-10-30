#!/bin/sh
# ShamiGo v0.10.366 Installer Fix1, native LMDE 7 / Debian 13.
# Start WITHOUT sudo: sh Install_ShamiGo_LMDE7.sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
DEB="$HERE/shamigo-fcitx5_0.10.366-1_amd64.deb"
CHECKER="$HERE/ShamiGo_Platform_Check.py"
PREFLIGHT="$HERE/ShamiGo_Dpkg_Preflight.sh"
if [ "$(id -u)" -eq 0 ]; then
  echo 'ERROR: run as your own Linux desktop account, without sudo.' >&2
  exit 2
fi
for app in python3 dpkg-deb sudo sha256sum apt-get; do
  command -v "$app" >/dev/null 2>&1 || { echo "ERROR: $app is missing." >&2; exit 2; }
done
[ -f "$CHECKER" ] && [ ! -L "$CHECKER" ] || { echo 'ERROR: missing OS compatibility checker. Extract entire ZIP.' >&2; exit 2; }
python3 "$CHECKER" || exit 2
if [ "$#" -eq 0 ]; then
  echo ''
  echo '=============================================='
  echo ' ShamiGo v0.10.366   LMDE 7 / Debian 13'
  echo '=============================================='
  echo ' [1] Install / upgrade (keep personal files)'
  echo ' [2] Remove ShamiGo program (keep personal files)'
  echo ' [3] Check installed files'
  echo ' [0] Exit'
  printf 'Select [1/2/3/0]: '
  IFS= read -r selection || exit 2
  case "$selection" in
    1) ACTION=install;; 2) ACTION=remove;; 3) ACTION=check;; 0) exit 0;;
    *) echo 'ERROR: select 0, 1, 2, or 3.' >&2; exit 2;;
  esac
else
  case "$1" in install|remove|check) ACTION=$1;; uninstall) ACTION=remove;; *) echo 'Usage: sh Install_ShamiGo_LMDE7.sh [install|remove|check]' >&2; exit 2;; esac
fi
if [ "$ACTION" = check ]; then
  if command -v shamigo-setup >/dev/null 2>&1; then
    exec shamigo-setup check
  fi
  echo 'ShamiGo is not currently installed.'
  exit 1
fi
if [ ! -f "$PREFLIGHT" ] || [ -L "$PREFLIGHT" ]; then
  echo 'ERROR: missing package manager preflight.' >&2; exit 2
fi
if [ "$ACTION" = install ]; then
  # Reject damaged or wrong-architecture packages before requesting sudo.
  [ -f "$DEB" ] && [ ! -L "$DEB" ] || { echo 'ERROR: .deb missing. Extract the whole ZIP first.' >&2; exit 2; }
  [ "$(dpkg-deb -f "$DEB" Package)" = shamigo-fcitx5 ] || exit 2
  [ "$(dpkg-deb -f "$DEB" Version)" = 0.10.366-1 ] || exit 2
  [ "$(dpkg-deb -f "$DEB" Architecture)" = amd64 ] || exit 2
  MANIFEST="$HERE/PACKAGE_SHA256.txt"
  [ -f "$MANIFEST" ] && [ ! -L "$MANIFEST" ] || { echo 'ERROR: missing checksum manifest.' >&2; exit 2; }
  (cd "$HERE" && sha256sum -c -- PACKAGE_SHA256.txt)
fi
printf '%s\n' '[1/4] Checking package manager (read-only)...'
sudo /bin/sh "$PREFLIGHT"
if [ "$ACTION" = remove ]; then
  printf '%s\n' '[2/4] Removing ShamiGo package (personal dictionaries/settings retained)...'
  # Restore while the helper still exists in the installed package.
  # Never touch an existing user-modified keyboard-us.conf.
  if command -v shamigo-link-fcitx-labels >/dev/null 2>&1; then
    shamigo-link-fcitx-labels restore || echo 'WARN: existing custom keyboard label left in place.'
  fi
  if dpkg-query -W -f='${Status}' shamigo-fcitx5 2>/dev/null | grep -q 'install ok installed'; then
    sudo /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get remove -y shamigo-fcitx5
  else
    echo 'ShamiGo not installed.'
  fi
  echo 'Removal finished. ~/.local/share/fcitx5/shamigo and personal config remain unchanged.'
  exit 0
fi
printf '%s\n' '[2/4] Installing / upgrading package with apt...'
sudo /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get --no-remove install -y "$DEB"
command -v shamigo-setup >/dev/null 2>&1 || { echo 'ERROR: setup tool not found after installation.' >&2; exit 1; }
printf '%s\n' '[3/4] Importing personal Liu dictionaries if provided (never overwrite)...'
if [ -f "$HERE/LicensedTables/liu-uni.tab" ] && [ ! -L "$HERE/LicensedTables/liu-uni.tab" ]; then
  shamigo-setup import-data --source "$HERE"
else
  echo 'No bundled personal Liu tables. Existing personal dictionary remains unchanged.'
fi
printf '%s\n' '[4/5] Linking Fcitx5 Eng / ShamiGo 嘸 labels (per-user)...'
shamigo-link-fcitx-labels install
printf '%s\n' '[5/5] Checking installation readiness...'

if [ ! -f "$HERE/LicensedTables/liu-uni.tab" ] &&
   [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/fcitx5/shamigo/liu-uni.tab" ]; then
  echo 'PACKAGE INSTALLED: no personal Liu dictionary is available yet.'
  echo 'Import a properly licensed table with:'
  echo '  shamigo-setup import-data --source /path/to/LicensedTables'
  echo 'Then check the installation with: shamigo-setup check --strict'
elif ! shamigo-setup check --strict; then
  echo 'Program package installed, but readiness is incomplete. Check personal dictionary and fcitx5 packages.' >&2
  exit 1
fi
echo 'ShamiGo installed. Restart Fcitx5 (or sign out/in) to show Eng / ShamiGo. The Qt6 toolbar follows the live Fcitx status.'

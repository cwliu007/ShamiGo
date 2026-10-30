#!/bin/sh
# ShamiGo v0.10.366 Installer Fix1: read-only package-manager preflight.
# This script intentionally NEVER removes lock files or automatically repairs
# unrelated package state. Run with sudo.
set -eu
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
  echo 'ERROR: package preflight requires sudo/root.' >&2
  exit 20
fi
for name in dpkg apt-get; do
  command -v "$name" >/dev/null 2>&1 || { echo "ERROR: missing $name" >&2; exit 20; }
done
if command -v fuser >/dev/null 2>&1; then
  for path in /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock /var/lib/apt/lists/lock; do
    if [ -e "$path" ] && fuser "$path" >/dev/null 2>&1; then
      echo 'ERROR: apt/dpkg is busy (LMDE Update Manager may be active). Close it and retry.' >&2
      exit 21
    fi
  done
fi
if [ -n "$(dpkg --audit 2>&1)" ]; then
  echo 'ERROR: dpkg has pending or broken packages. No automatic repair was attempted.' >&2
  echo 'Check in LMDE: sudo dpkg --configure -a' >&2
  exit 22
fi
if ! apt-get check >/dev/null 2>&1; then
  echo 'ERROR: apt dependencies are inconsistent. No automatic repair was attempted.' >&2
  echo 'Review in LMDE: sudo apt --fix-broken install' >&2
  exit 23
fi
echo 'SHAMIGO_PKG_OK: package manager is ready.'

#!/bin/sh
# v0.10.366 VirtualBox Guest Control installer. Debian 13/LMDE 7 amd64 only.
# Called as the guest's NORMAL desktop user, never the Windows user/root.
set -eu
ACTION=${1-}
STAGE=${2-}
EXPECTED_SHA=${3-}
BASE=ShamiGo_v0.10.366
PAYLOAD=ShamiGo_v0.10.366_VM_Payload.tar.gz
DEB=shamigo-fcitx5_0.10.366-1_amd64.deb
case "$ACTION" in install|remove) ;; *) echo 'ERROR: action must be install/remove.' >&2; exit 2;; esac
if ! printf '%s\n' "$STAGE" | grep -Eq '^/tmp/shamigo-v366-[a-f0-9]{32}$'; then
  echo 'ERROR: invalid guest stage path.' >&2; exit 2
fi
if [ "$(id -u)" -eq 0 ] || [ ! -d "$STAGE" ] || [ -L "$STAGE" ]; then
  echo 'ERROR: unsafe stage or root session.' >&2; exit 2
fi
if [ "$(stat -c %u "$STAGE")" != "$(id -u)" ] || [ "$(stat -c %a "$STAGE")" != 700 ]; then
  echo 'ERROR: unexpected stage owner or permissions.' >&2; exit 2
fi
PWFILE="$STAGE/shamigo-credential.tmp"
umask 077
trap 'rm -f -- "$PWFILE"' EXIT
trap 'exit 130' HUP INT TERM
[ -f "$PWFILE" ] && [ ! -L "$PWFILE" ] || { echo 'ERROR: guest sudo credential missing.' >&2; exit 2; }
chmod 600 "$PWFILE"
command -v python3 >/dev/null && command -v sudo >/dev/null && command -v dpkg-deb >/dev/null || {
  echo 'ERROR: LMDE missing required python3/sudo/dpkg-deb.' >&2; exit 2;
}
[ -f "$STAGE/ShamiGo_Platform_Check.py" ] && [ ! -L "$STAGE/ShamiGo_Platform_Check.py" ] || exit 2
python3 "$STAGE/ShamiGo_Platform_Check.py" || exit 2
[ -f "$STAGE/ShamiGo_Dpkg_Preflight.sh" ] && [ ! -L "$STAGE/ShamiGo_Dpkg_Preflight.sh" ] || exit 2
sudo_step() {
  # Do not put the sudo password on the command line or in logs.
  (cat "$PWFILE"; printf '\n') | sudo -S -p '' "$@"
}
echo '[1/4] Checking apt/dpkg state (read-only)...'
sudo_step /bin/sh "$STAGE/ShamiGo_Dpkg_Preflight.sh"
if [ "$ACTION" = install ]; then
  printf '%s\n' "$EXPECTED_SHA" | grep -Eq '^[a-fA-F0-9]{64}$' || {
    echo 'ERROR: payload digest is invalid.' >&2; exit 2;
  }
  [ -f "$STAGE/$PAYLOAD" ] && [ ! -L "$STAGE/$PAYLOAD" ] || {
    echo 'ERROR: VM install payload missing.' >&2; exit 2;
  }
  echo '[2/4] Checking transferred payload SHA-256 and tar layout...'
  (cd "$STAGE" && printf '%s  %s\n' "$EXPECTED_SHA" "$PAYLOAD" | sha256sum -c -)
  # Check types, paths, duplicates and sizes BEFORE extraction.  Listing names
  # with `tar -tzf` alone does not reject symlinks, hardlinks or duplicate files.
  # Write ONLY regular files with exclusive creation: no links or overwrites.
  python3 - "$STAGE/$PAYLOAD" "$STAGE" "$BASE" "$DEB" <<'PYSAFE'
import os
import pathlib
import shutil
import sys
import tarfile

archive, stage, base, deb = sys.argv[1:]
allowed = {
    f'{base}/{deb}',
    f'{base}/LicensedTables/liu-uni.tab',
    f'{base}/LicensedTables/liu-uni2.tab',
    f'{base}/LicensedTables/liu-uni4.tab',
}
try:
    with tarfile.open(archive, 'r:gz') as tar:
        members = tar.getmembers()
        names = [m.name for m in members]
        # Personal releases can carry individually licensed tables. Public
        # releases contain the exact same .deb but no private tables at all.
        # Both inventories must be safe, and the package is always required.
        if (f'{base}/{deb}' not in names or not set(names).issubset(allowed)
                or len(names) != len(set(names))):
            raise ValueError('Unexpected, duplicated, or missing archive member')
        if any(not m.isfile() or m.size < 1 or m.size > 64 * 1024 * 1024
               for m in members):
            raise ValueError('Archive contains a non-regular file or excessive size')
        root = pathlib.Path(stage) / base
        (root / 'LicensedTables').mkdir(parents=True, exist_ok=False, mode=0o700)
        for member in members:
            destination = pathlib.Path(stage).joinpath(*member.name.split('/'))
            with tar.extractfile(member) as source:
                if source is None:
                    raise ValueError('Cannot read archive member')
                flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
                if hasattr(os, 'O_NOFOLLOW'):
                    flags |= os.O_NOFOLLOW
                fd = os.open(destination, flags, 0o600)
                with os.fdopen(fd, 'wb') as target:
                    copied = shutil.copyfileobj(source, target)
            if destination.stat().st_size != member.size:
                raise ValueError('Archive member size mismatch')
except (OSError, EOFError, ValueError, tarfile.TarError) as exc:
    print('ERROR: refusing unsafe VM payload: {}'.format(exc), file=sys.stderr)
    sys.exit(2)
PYSAFE
  pkg="$STAGE/$BASE/$DEB"
  [ -f "$pkg" ] && [ ! -L "$pkg" ] || exit 2
  [ "$(dpkg-deb -f "$pkg" Package)" = shamigo-fcitx5 ] || exit 2
  [ "$(dpkg-deb -f "$pkg" Version)" = 0.10.366-1 ] || exit 2
  [ "$(dpkg-deb -f "$pkg" Architecture)" = amd64 ] || exit 2
  echo '[3/4] Installing ShamiGo with apt (dependencies downloaded if required)...'
  sudo_step /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get --no-remove install -y "$pkg"
  command -v shamigo-setup >/dev/null 2>&1 || { echo 'ERROR: shamigo-setup missing after installation.' >&2; exit 1; }
  echo '[4/4] Importing individually owned dictionaries (keep previous files)...'
  if [ -f "$STAGE/$BASE/LicensedTables/liu-uni.tab" ]; then
    shamigo-setup import-data --source "$STAGE/$BASE"
  fi
  # Execute as authenticated desktop account, not in the sudo subprocess.
  # Does not edit existing profiles, XKB maps, or user-provided IM configs.
  shamigo-link-fcitx-labels install
  if [ ! -f "$STAGE/$BASE/LicensedTables/liu-uni.tab" ] &&
     [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/fcitx5/shamigo/liu-uni.tab" ]; then
    echo 'PACKAGE INSTALLED: no personal Liu dictionary bundled or already imported.'
    echo 'Import your properly licensed table in the Linux guest with:'
    echo '  shamigo-setup import-data --source /path/to/LicensedTables'
    echo 'Then run: shamigo-setup check --strict'
  else
    shamigo-setup check --strict || {
      echo 'ERROR: installed package but ShamiGo readiness check failed. Review dictionary/Fcitx5 requirements.' >&2
      exit 1
    }
  fi
  echo 'Installed. In the LMDE graphical session, open Fcitx5 configuration and add ShamiGo. Restart Fcitx5/log out if needed.'
else
  echo '[2/4] Removing only system ShamiGo package; user dictionaries/settings are left untouched...'
  # The binary comes from the installed .deb, so restore BEFORE apt remove.
  if command -v shamigo-link-fcitx-labels >/dev/null 2>&1; then
    shamigo-link-fcitx-labels restore || echo 'WARN: personal custom keyboard label retained.'
  fi
  if dpkg-query -W -f='${Status}' shamigo-fcitx5 2>/dev/null | grep -q 'install ok installed'; then
    sudo_step /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get remove -y shamigo-fcitx5
  else
    echo 'No installed ShamiGo package to remove.'
  fi
  echo 'Personal data and Fcitx5 profile preserved.'
fi
printf '%s\n' 'SHAMIGO_RESULT=OK'

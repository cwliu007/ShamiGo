#!/bin/bash
# ShamiGo macOS full removal (current user only).
# Removes only identified ShamiGo-owned files; no elevated privileges.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HELPER="$ROOT/shamigo_tis_tool"
APP="$HOME/Library/Input Methods/ShamiGo.app"
APP_LEGACY="/Library/Input Methods/ShamiGo.app"
LSREG='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
EXPECTED='tw.shamigo.inputmethod.macos'
LEGACY='tw.shamigo.inputmethod.mac'
LAUNCH_LABEL='tw.shamigo.inputmethod.switcher'
LAUNCH_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_LABEL.plist"

error() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
log() { printf '[UNINSTALL] %s\n' "$*"; }
[[ "$(/usr/bin/uname -s)" == Darwin ]] || error 'macOS required.'
[[ "$(/usr/bin/id -u)" -ne 0 ]] || error 'Do not run as root or use sudo; uninstall the current user only.'
[[ "$HOME" == /* && "$HOME" != '/' && -d "$HOME/Library" ]] || error 'Cannot verify current-user Library path.'
for parent in "$HOME/Library" "$HOME/Library/Input Methods" \
  "$HOME/Library/Application Support" "$HOME/Library/Caches" \
  "$HOME/Library/Logs" "$HOME/Library/Preferences" \
  "$HOME/Library/Saved Application State" "$HOME/Library/LaunchAgents" \
  "$HOME/Library/HTTPStorages" "$HOME/Library/WebKit" \
  "$HOME/Library/Containers"; do
  [[ ! -L "$parent" ]] || error "Symbolic-link parent, refusing to remove data: $parent"
done

app_id() { /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null || true; }
[[ ! -L "$APP" ]] || error "Symbolic-link App, refusing to remove: $APP"
if [[ -e "$APP" ]]; then
  [[ -d "$APP" ]] || error 'Unexpected App target (not a directory).'
  id="$(app_id "$APP")"
  [[ "$id" == "$EXPECTED" || "$id" == "$LEGACY" ]] || error "Unexpected App bundle identifier: $id"
fi

# Validate legacy LaunchAgent identity before disabling/deleting it.
if [[ -e "$LAUNCH_PLIST" || -L "$LAUNCH_PLIST" ]]; then
  [[ -f "$LAUNCH_PLIST" && ! -L "$LAUNCH_PLIST" ]] || error 'Unexpected legacy agent path.'
  label="$(/usr/libexec/PlistBuddy -c 'Print Label' "$LAUNCH_PLIST" 2>/dev/null || true)"
  [[ "$label" == "$LAUNCH_LABEL" ]] || error 'Legacy agent label does not belong to ShamiGo.'
fi

# The bundled helper speaks a fixed 479 safety protocol. Do not delete an
# active input method until macOS has confirmed it is no longer selected.
if [[ -x "$HELPER" && "$("$HELPER" --protocol-version 2>/dev/null || true)" == 479 ]]; then
  if ! "$HELPER" --select-abc; then
    "$HELPER" --safe-to-uninstall || error 'Switch to ABC in the input menu, then run uninstall again.'
  fi
  "$HELPER" --disable-owned || error 'macOS refused to disable the ShamiGo input source. App/data not deleted.'
  "$HELPER" --safe-to-uninstall || error 'ShamiGo input source still active. App/data not deleted.'
else
  [[ ! -d "$APP" ]] || error 'The bundled macOS input-source helper is unavailable. App/data not deleted.'
  log 'Input-source helper missing, but no ShamiGo.app is installed; cleaning user data only.'
fi

# Stop only the current user's exact ShamiGo processes / launchd label.
/bin/launchctl bootout "gui/$(/usr/bin/id -u)/$LAUNCH_LABEL" >/dev/null 2>&1 || true
/usr/bin/pkill -u "$(/usr/bin/id -u)" -x ShamiGoSwitcherAgent >/dev/null 2>&1 || true
/usr/bin/pkill -u "$(/usr/bin/id -u)" -x ShamiGoIME >/dev/null 2>&1 || true
if [[ -x "$LSREG" && -d "$APP" ]]; then "$LSREG" -u "$APP" || true; fi

remove_owned() {
  local path="$1"
  [[ "$path" == "$HOME/Library/"* && "$path" != "$HOME/Library/" ]] || error "Unsafe removal target: $path"
  [[ ! -L "$path" ]] || error "Refusing to follow or erase symlink: $path"
  if [[ -e "$path" ]]; then
    /bin/rm -rf -- "$path" || error "Could not delete $path"
    log "Removed $path"
  fi
}

remove_owned "$APP"
remove_owned "$LAUNCH_PLIST"
# Entire ShamiGo-owned user directory includes licensed roots, dictionaries,
# custom settings, caches, build data, diagnostics and backups.
remove_owned "$HOME/Library/Application Support/ShamiGo"
remove_owned "$HOME/Library/Caches/ShamiGo"
remove_owned "$HOME/Library/Logs/ShamiGo"
remove_owned "$HOME/Library/HTTPStorages/$EXPECTED"
remove_owned "$HOME/Library/HTTPStorages/$LEGACY"
remove_owned "$HOME/Library/WebKit/$EXPECTED"
remove_owned "$HOME/Library/WebKit/$LEGACY"
remove_owned "$HOME/Library/Containers/$EXPECTED"
remove_owned "$HOME/Library/Containers/$LEGACY"
remove_owned "$HOME/Library/Saved Application State/$EXPECTED.savedState"
remove_owned "$HOME/Library/Saved Application State/$LEGACY.savedState"
# Flush only ShamiGo's preferences, not shared Apple keyboard settings.
/usr/bin/defaults delete "$EXPECTED" >/dev/null 2>&1 || true
/usr/bin/defaults delete "$LEGACY" >/dev/null 2>&1 || true
remove_owned "$HOME/Library/Preferences/$EXPECTED.plist"
remove_owned "$HOME/Library/Preferences/$LEGACY.plist"
remove_owned "$HOME/Library/Preferences/$LAUNCH_LABEL.plist"

# Remove own orphaned old-installer stage/rollback directories only when their
# saved App has a valid ShamiGo bundle ID; never touch other applications.
shopt -s nullglob
for folder in "$HOME/Library/Input Methods"/.ShamiGo-offline-stage-* \
              "$HOME/Library/Input Methods"/.ShamiGo-offline-backup-* \
              "$HOME/Library/Input Methods"/.ShamiGo-stage-* \
              "$HOME/Library/Input Methods"/.ShamiGo-rollback-*; do
  [[ -d "$folder" && ! -L "$folder" ]] || error "Unexpected leftover installer path: $folder"
  if [[ -d "$folder/ShamiGo.app" && ! -L "$folder/ShamiGo.app" ]]; then
    id="$(app_id "$folder/ShamiGo.app")"
    [[ "$id" == "$EXPECTED" || "$id" == "$LEGACY" ]] || error "Unknown App in installer staging folder: $folder"
  fi
  remove_owned "$folder"
done
shopt -u nullglob

# Current user installation includes historical ShamiGoMac installer logs.
# Keep original downloads, privately compiled projects and unrelated files;
# the README's downloaded public release ZIP is removed only after success.
shopt -s nullglob
for log_file in "$HOME/Downloads"/ShamiGoMac_install-*.log \
                "$HOME/Downloads"/ShamiGoMac_uninstall-*.log \
                "$HOME/Downloads"/ShamiGoMac_build-*.log \
                "$HOME/Downloads"/ShamiGoMac_prepare-*.log \
                "$HOME/Downloads"/ShamiGoMac_refresh-*.log \
                "$HOME/Downloads"/ShamiGoMac_restore_caret-*.log; do
  [[ -f "$log_file" && ! -L "$log_file" ]] || error "Unexpected log path: $log_file"
  /bin/rm -f -- "$log_file"
done
shopt -u nullglob

for path in "$APP" "$LAUNCH_PLIST" \
  "$HOME/Library/Application Support/ShamiGo" "$HOME/Library/Caches/ShamiGo" \
  "$HOME/Library/Logs/ShamiGo" \
  "$HOME/Library/Preferences/$EXPECTED.plist" "$HOME/Library/Preferences/$LEGACY.plist"; do
  [[ ! -e "$path" && ! -L "$path" ]] || error "Residual file still exists: $path"
done
if [[ -d "$APP_LEGACY" ]]; then
  log "WARNING: A system-wide installation exists at $APP_LEGACY; not modified without admin permission."
fi
if [[ -x "$HELPER" && "$("$HELPER" --protocol-version 2>/dev/null || true)" == 479 ]]; then
  if ! "$HELPER" --check-gone; then
    log 'macOS is still caching a ShamiGo input source. Log out and log back in; if necessary remove it in Keyboard settings.'
  fi
fi
log 'ShamiGo current-user App, licensed tables, preferences, dictionaries and caches removed.'
log 'Please log out and log back in to refresh the macOS keyboard menu.'
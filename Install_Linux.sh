#!/bin/sh
# Install/upgrade Linux package as the desktop user. Do not run with sudo.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
exec /bin/sh "$HERE/Packages/Linux/Install_ShamiGo_Linux.sh" install

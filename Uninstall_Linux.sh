#!/bin/sh
# Remove system package while keeping personal dictionary/configuration.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
exec /bin/sh "$HERE/Packages/Linux/Install_ShamiGo_Linux.sh" remove

#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
exec /bin/sh "$HERE/Install_ShamiGo_Linux.sh" remove

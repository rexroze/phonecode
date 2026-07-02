#!/bin/sh
# Compatibility wrapper. The interactive installer is now scripts/install.sh.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec sh "$SCRIPT_DIR/install.sh" "$@"

#!/bin/bash


# ----------------------------
# config.sh
# Script library directories
#
# Resolve paths relative to this file so
# the framework can run from any location.
# ----------------------------

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CORE_LIB_DIR="$SCRIPT_ROOT/lib/core"
export BACKUP_LIB_DIR="$SCRIPT_ROOT/lib/backup"
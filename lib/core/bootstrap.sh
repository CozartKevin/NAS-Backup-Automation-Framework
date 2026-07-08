#!/bin/bash

# ----------------------------
# bootstrap.sh
# NAS Script Initialization Layer
# ----------------------------

bootstrap_init() {

    # ----------------------------
    # Safety mode
    # ----------------------------
    set -euo pipefail
    export LC_ALL=C
    export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

    # ----------------------------
    # Identity validation
    # ----------------------------
    : "${SYSTEM_NAME:=UNSPECIFIED_SYSTEM}"
    : "${SERVICE_NAME:=UNKNOWN}"
    : "${NODE_NAME:=UNKNOWN}"
    : "${EXECUTION_MODE:?EXECUTION_MODE must be set (LIVE|DRY_RUN)}"

    # ----------------------------
    # Core runtime metadata
    # ----------------------------
    export RUN_ID="${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$}"
    export SCRIPT_NAME="$(basename "$0")"
    export HOSTNAME="$(hostname)"

    # ----------------------------
    # Load config FIRST (before anything else)
    # ----------------------------
    LIB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$LIB_ROOT/config.sh"

    : "${CORE_LIB_DIR:?missing CORE_LIB_DIR}"
    : "${BACKUP_LIB_DIR:?missing BACKUP_LIB_DIR}"


    # ----------------------------
    # Load libraries (centralized)
    # ----------------------------
    source "$CORE_LIB_DIR/logging.sh"
    source "$CORE_LIB_DIR/lock.sh"
    source "$CORE_LIB_DIR/timer.sh"
    source "$CORE_LIB_DIR/file_ops.sh"
    source "$CORE_LIB_DIR/execution.sh"
    source "$CORE_LIB_DIR/preflight.sh"


    # ----------------------------
    # Logging setup (must exist after sourcing logging.sh)
    # ----------------------------
    setup_logging


    # ----------------------------
    # Execution mode validation
    # ----------------------------

    case "$EXECUTION_MODE" in
    LIVE|DRY_RUN) ;;
    *)
        log_event "ERROR" "VALIDATE" "bootstrap" "0" "FAIL" "invalid EXECUTION_MODE"
        exit 2
        ;;
    esac


    # ----------------------------
    # Start log entry
    # ----------------------------
    log_event "INFO" "BOOT" "script" "0" "SUCCESS" "bootstrap initialized"

    # ----------------------------
    # Optional timer start
    # ----------------------------
    export SCRIPT_START_TIME
    SCRIPT_START_TIME=$(start_timer)
}
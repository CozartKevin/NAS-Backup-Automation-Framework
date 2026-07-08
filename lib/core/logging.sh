#!/bin/bash

# ----------------------------
# RUN CONTEXT (Stage 3)
# ----------------------------
RUN_ID="${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$}"

# --- Log Events ---
log_event() {
      if [[ $# -ne 6 ]]; then
        # Avoid recursion into logging system
        >&2 echo "log_event contract violation: expected 6 args, got $#"
        return 2
    fi

    local level="$1"
    local system="${SYSTEM_NAME:-UNKNOWN}"
    local service="${SERVICE_NAME:-UNKNOWN}"
    local node="${NODE_NAME:-UNKNOWN}"
    local action="$2"
    local target="$3"
    local metric="$4"
    local result="$5"
    local message="$6"

    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') | $RUN_ID | $level | $system | $service | $node | $action | $target | $metric | $result | $message"
}


# --- Error handling ---
error_trap() {
    local exit_code=$?

    set +e
    log_event \
        "ERROR" \
        "RUNTIME_ERROR" \
        "$BASH_COMMAND" \
        "$LINENO" \
        "FAIL" \
        "command failed exit_code=$exit_code"
    set -e

    exit "$exit_code"
}

# --- Setup ---
setup_logging() {
    : "${LOG_FILE:?LOG_FILE must be set before calling setup_logging}"

    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"

    # send ALL output to file
    exec >> "$LOG_FILE" 2>&1

    trap error_trap ERR
}

log_run_complete() {
    local duration="$1"
    local success="$2"
    local fails="$3"

    log_event "INFO" "RUN_COMPLETE" "script" \
        "duration=${duration};success=${success};fails=${fails}" \
        "SUCCESS" \
        "job finished"
}
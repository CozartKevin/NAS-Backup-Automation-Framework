#!/bin/bash

# ----------------------------
# LOCK LIBRARY (CLEAN CONTRACT)
# Depends ONLY on logging.sh (6-arg format)
# ----------------------------

LOCK_ACQUIRED=0

acquire_lock() {
    local lock_file="$1"

    log_event "INFO" "LOCK_CHECK" "$lock_file" "0" "START" "checking lock"

    if ( set -o noclobber; : > "$lock_file" ) 2>/dev/null; then
        LOCK_ACQUIRED=1
        log_event "INFO" "LOCK_ACQUIRE" "$lock_file" "1" "SUCCESS" "lock acquired"
        return 0
    fi

    LOCK_ACQUIRED=0
    log_event "WARN" "LOCK_DENY" "$lock_file" "0" "FAIL" "lock already exists"
    return 1
}

release_lock() {
    local lock_file="$1"

    if [[ "$LOCK_ACQUIRED" -eq 1 && -f "$lock_file" ]]; then
        rm -f "$lock_file"
        LOCK_ACQUIRED=0
        log_event "INFO" "LOCK_RELEASE" "$lock_file" "0" "SUCCESS" "lock released"
    else
        log_event "WARN" "LOCK_RELEASE" "$lock_file" "0" "SKIP" "no active lock"
    fi
}

check_lock() {
    local lock_file="$1"

    if [[ -f "$lock_file" ]]; then
        log_event "WARN" "LOCK_CHECK" "$lock_file" "0" "FAIL" "lock exists"
        return 1
    fi

    log_event "INFO" "LOCK_CHECK" "$lock_file" "0" "SUCCESS" "no lock present"
    return 0
}

with_lock() {
    local lock_file="$1"
    shift

    if acquire_lock "$lock_file"; then
        trap 'release_lock "'"$lock_file"'"' EXIT
        "$@"
        return $?
    fi

    return 1
}
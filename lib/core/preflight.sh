#!/bin/bash

# ----------------------------
# Preflight Library
# Validates system readiness before execution
# ----------------------------

# Return Codes:
# 0 = OK
# 1 = SRC invalid
# 2 = DST invalid
# 3 = Insufficient space

preflight_checks() {
    local SRC="$1"
    local DST="$2"

    # --- validate inputs ---
    [[ -n "$SRC" ]] || return 1
    [[ -n "$DST" ]] || return 2

    [[ -d "$SRC" ]] || return 1
    [[ -d "$DST" ]] || return 2

    # --- disk space check ---
    local MIN_SPACE=$((50 * 1024 * 1024))  # KB
    local AVAIL_SPACE

    AVAIL_SPACE=$(df -k "$DST" | awk 'NR==2 {print $4}')

    if (( AVAIL_SPACE < MIN_SPACE )); then
        return 3
    fi

    return 0
}


preflight_validate() {
    local SRC="$1"
    local DST="$2"

    preflight_checks "$SRC" "$DST"
    local rc=$?

    case "$rc" in
        0)
            log_event "INFO" "VALIDATE" "$SRC" "0" "OK" "SRC validated"
            log_event "INFO" "VALIDATE" "$DST" "0" "OK" "DST validated"
            log_event "INFO" "VALIDATE" "SYSTEM" "0" "OK" "preflight passed"
            return 0
            ;;

        1)
            log_event "ERROR" "VALIDATE" "$SRC" "0" "FAIL" "SRC invalid or missing"
            exit 1
            ;;

        2)
            log_event "ERROR" "VALIDATE" "$DST" "0" "FAIL" "DST invalid or missing"
            exit 2
            ;;

        3)
            log_event "ERROR" "VALIDATE" "$DST" "0" "FAIL" "Insufficient disk space"
            exit 3
            ;;

        *)
            log_event "ERROR" "VALIDATE" "$SRC" "0" "FAIL" "unknown preflight error: $rc"
            exit 99
            ;;
    esac
}

preflight_validate_path(){

    local path="$1"

    if [ ! -d "$path" ]; then

        log_event "ERROR" "VALIDATE" "$path" "0" "FAIL" "directory missing"

        return 1

    fi

    log_event "INFO" "VALIDATE" "$path" "0" "OK" "path validated"

    return 0
}
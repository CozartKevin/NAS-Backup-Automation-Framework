#!/bin/bash

# ----------------------------
# Backup Date Utility Library
# ----------------------------

# EXPECTED FORMAT:
#   YYYYMMDD_folderName
#
# Examples:
#   20260430_Backup
#   20260530_VMBackup
#
# All functions operate on the DATE PREFIX ONLY.

if [[ "${BACKUP_DATES_LOADED:-0}" -eq 1 ]]; then
    return 0
fi

export BACKUP_DATES_LOADED=1


# ----------------------------
# RAW DISCOVERY
# ----------------------------
list_date_folders() {
    local dir="$1"

    find "$dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf "%f\n" 2>/dev/null \
    | grep -E '^[0-9]{8}_' || true
}


# TODO 
# Create backup_disovery.sh 
# MOVE TO A backup_discovery.sh lib
# implement 
# list_date_prefixed_folders
# get-backup_folders_for_date()

# -------------------------------------------------------------------------------------------

list_non_date_folders() {
    local dir="$1"

    [[ -d "$dir" ]] || return 2

    find "$dir" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -regextype posix-extended \
    ! -name '@eaDir' \
    ! -regex '.*/[0-9]{8}_.*' \
    -printf '%f\n' | sort
}

# -------------------------------------------------------------------------------------------

# ----------------------------
# DATE EXTRACTION
# ----------------------------
get_unique_dates() {
    local dir="$1"

    list_date_folders "$dir" \
        | cut -d'_' -f1 \
        | sort -u
}

# ----------------------------
# DATE COUNT
# ----------------------------
get_date_stats() {
    local dir="$1"

    get_unique_dates "$dir" \
        | wc -l \
        | tr -d ' '
}

# ----------------------------
# ORDERED SELECTION
# ----------------------------
get_date_by_order() {
    local dir="$1"
    local order="${2:-newest}"

    case "$order" in
        newest)
            get_unique_dates "$dir" \
                | sort -r \
                | head -n 1 || true
            ;;
        oldest)
            get_unique_dates "$dir" \
                | sort \
                | head -n 1 || true
            ;;
        *)
            return 1
            ;;
    esac
}

# ----------------------------
# LOGGING / DEBUG HELPER
# ----------------------------
debug_print_dates() {
    local dir="$1"

    get_unique_dates "$dir" \
        | paste -sd ';' -
}

# ----------------------------
# CONTEXT HELPER
# ----------------------------
get_date_context() {
    local dir="$1"

    local count
    local oldest
    local newest
    local dates

    count=$(get_date_stats "$dir")
    oldest=$(get_date_by_order "$dir" oldest)
    newest=$(get_date_by_order "$dir" newest)
    dates=$(debug_print_dates "$dir")

    printf '%s|%s|%s|%s\n' \
        "$count" \
        "$oldest" \
        "$newest" \
        "$dates"
}

# ----------------------------
#  DATE PREFIX FOLDER DISCOVERY
# ----------------------------
get_folders_for_date() {
    local dir="$1"
    local date_prefix="$2"

    [[ -d "$dir" ]] || return 2
    [[ "$date_prefix" =~ ^[0-9]{8}$ ]] || return 2

    find "$dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name "${date_prefix}_*" \
        -printf "%f\n" \
        2>/dev/null \
        | sort
}
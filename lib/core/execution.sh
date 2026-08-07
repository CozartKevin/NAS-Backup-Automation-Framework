#!/bin/bash

# =========================================================
# execution.sh (POLICY LAYER)
# - Controls DRY_RUN vs LIVE behavior
# - Handles execution logging
# - Delegates IO to file_ops.sh
# =========================================================

: "${EXECUTION_MODE:?EXECUTION_MODE not set}"

# ---------------------------------------------------------
# COPY EXECUTION
# ---------------------------------------------------------
execute_copy() {
    local src="$1"
    local dst="$2"
    local name="$3"

    case "$EXECUTION_MODE" in

        DRY_RUN)
            log_event "INFO" "COPY" "$name" "0" "SIMULATED" "would copy"
            return 0
            ;;

        LIVE)
            log_event "INFO" "COPY" "$name" "0" "START" "copying"

            file_ops_copy "$src" "$dst"
            local rc=$?

            case "$rc" in
                0)
                    log_event "INFO" "COPY" "$name" "0" "SUCCESS" "copied"
                    ;;
                1)
                    log_event "ERROR" "COPY" "$name" "0" "FAIL" "rsync failed"
                    ;;
                2)
                    log_event "ERROR" "COPY" "$name" "0" "FAIL" "invalid input"
                    ;;
                *)
                    log_event "ERROR" "COPY" "$name" "0" "FAIL" "unknown error code: $rc"
                    ;;
            esac

            return "$rc"
            ;;

        *)
            log_event "ERROR" "VALIDATE" "$name" "0" "FAIL" "invalid EXECUTION_MODE=$EXECUTION_MODE"
            return 2
            ;;
    esac
}

execute_move() {
    local src="$1"
    local dst="$2"
    local name="$3"

    case "$EXECUTION_MODE" in

        DRY_RUN)
            log_event "INFO" "MOVE" "$name" "0" "SIMULATED" "would move"
            return 0
            ;;

        LIVE)
            log_event "INFO" "MOVE" "$name" "0" "START" "moving"

            file_ops_move "$src" "$dst"
            local rc=$?

            case "$rc" in
                0)
                    log_event "INFO" "MOVE" "$name" "0" "SUCCESS" "moved"
                    ;;
                1)
                    log_event "ERROR" "MOVE" "$name" "0" "FAIL" "move operation failed"
                    ;;
                2)
                    log_event "ERROR" "MOVE" "$name" "0" "FAIL" "invalid input"
                    ;;
                *)
                    log_event "ERROR" "MOVE" "$name" "0" "FAIL" "unknown error code: $rc"
                    ;;
            esac

            return "$rc"
            ;;

        *)
            log_event "ERROR" "VALIDATE" "$name" "0" "FAIL" "invalid EXECUTION_MODE=$EXECUTION_MODE"
            return 2
            ;;
    esac
}


# ---------------------------------------------------------
# DELETE EXECUTION
# ---------------------------------------------------------
execute_delete() {
    local target="$1"
    local name="$2"

    case "$EXECUTION_MODE" in

        DRY_RUN)
            log_event "INFO" "DELETE" "$name" "0" "SIMULATED" "would delete"
            return 0
            ;;

        LIVE)
            log_event "INFO" "DELETE" "$name" "0" "START" "deleting"

            file_ops_delete "$target"
            local rc=$?

            case "$rc" in
                0)
                    log_event "INFO" "DELETE" "$name" "0" "SUCCESS" "deleted"
                    ;;
                1)
                    log_event "ERROR" "DELETE" "$name" "0" "FAIL" "rm failed"
                    ;;
                2)
                    log_event "ERROR" "VALIDATE" "$name" "0" "FAIL" "invalid input"
                    ;;
                *)
                    log_event "ERROR" "DELETE" "$name" "0" "FAIL" "unknown error code: $rc"
                    ;;
            esac

            return "$rc"
            ;;

        *)
            log_event "ERROR" "VALIDATE" "$name" "0" "FAIL" "invalid EXECUTION_MODE=$EXECUTION_MODE"
            return 2
            ;;
    esac
}
execute_sync() {
    local src_path="$1"
    local dst_path="$2"
    local name="$3"

    log_event "INFO" "SYNC" "$name" "0" "START" "destination exists; verifying/updating"

    local sync_output
    sync_output=$(file_ops_sync "$src_path" "$dst_path")
    local rc=$?

    if [[ "$rc" -ne 0 ]]; then
        log_event "ERROR" "SYNC" "$name" "$rc" "FAIL" "sync failed"
        return "$rc"
    fi

    if [[ -z "$sync_output" ]]; then
        log_event "INFO" "SYNC" "$name" "0" "NO_CHANGE" "destination already current"
    else
        log_event "INFO" "SYNC" "$name" "0" "UPDATED" "destination updated"
    fi

    return 0
}


execute_clean_dir() {

    local target="$1"
    local name="$2"


    case "$EXECUTION_MODE" in

        DRY_RUN)
            log_event "INFO" "CLEAN" "$name" "0" "SIMULATED" "would remove empty directory"
            return 0
            ;;


        LIVE)

            log_event "INFO" "CLEAN" "$name" "0" "START" "removing empty directory"

            file_ops_remove_empty_dir_tree $target

            local rc=$?

            case "$rc" in
                0)
                    log_event "INFO" "CLEAN" "$name" "0" "SUCCESS" "empty directory removed"
                    ;;
                *)
                    log_event "ERROR" "CLEAN" "$name" "0" "FAIL" "cleanup failed"
                    ;;
            esac

            return "$rc"
            ;;


        *)
            log_event "ERROR" "VALIDATE" "$name" "0" "FAIL" "invalid EXECUTION_MODE=$EXECUTION_MODE"
            return 2
            ;;

    esac
}

execute_rename() {
    local src="$1"
    local dst="$2"
    local name="$3"
    
    local rename_dst
    rename_dst="${name}->$(basename "$dst")"


    case "$EXECUTION_MODE" in
        DRY_RUN)
            log_event "INFO" "RENAME" "$rename_dst" "0" "SIMULATED" "would rename"
            return 0
            ;;

        LIVE)
            log_event "INFO" "RENAME" "$rename_dst" "0" "START" "renaming"

            file_ops_rename_directory "$src" "$dst"
            local rc=$?

            case "$rc" in
                0)
                    log_event "INFO" "RENAME" "$rename_dst" "$rc" "SUCCESS" "renamed"
                    ;;
                1)
                    log_event "ERROR" "RENAME" "$rename_dst" "$rc" "FAIL" "rename operation failed"
                    ;;
                2)
                    log_event "ERROR" "RENAME" "$rename_dst" "$rc" "FAIL" "invalid input"
                    ;;
                3)
                    log_event "ERROR" "RENAME" "$rename_dst" "$rc" "FAIL" "destination already exists"
                    ;;
                *)
                    log_event "ERROR" "RENAME" "$rename_dst" "$rc" "FAIL" "unknown error code: $rc"
                    ;;
            esac

            return "$rc"
            ;;

        *)
            log_event "ERROR" "VALIDATE" "$rename_dst" "2" "FAIL" "invalid EXECUTION_MODE=$EXECUTION_MODE"
            return 2
            ;;
    esac
}
#!/bin/bash
set -euo pipefail


# DRY_RUN logs intended actions without changing files.
# Change to LIVE only after validating paths, logs, and expected behavior.
export EXECUTION_MODE="DRY_RUN"

# ----------------------------
# Identity
#
# These values appear in every structured log line.
# ----------------------------
SYSTEM_NAME="NAS-COPY"
SERVICE_NAME="CopyWeeklyBackupsExample"
NODE_NAME="ExampleNAS"

export SYSTEM_NAME SERVICE_NAME NODE_NAME EXECUTION_MODE

# ----------------------------
# Config
#
# LOG_FILE controls where this workflow writes logs.
# LOCK_FILE prevents overlapping runs of the same job.
# ----------------------------
LOG_FILE="/mnt/logs/CopyWeeklyBackupsExample/$(date +'%Y%m%d')_copy_weekly_backup.log"
LOCK_FILE="/tmp/copy_weekly_backup_example.lock"

# ----------------------------
# Paths
#
# SRC contains the backup folders to process.
# DST is the copy destination.
# EXPECTED_COUNT is advisory; mismatches are logged for visibility.
# ----------------------------
SRC="/mnt/primary_storage/windows_image_backups"
DST="/mnt/secondary_storage/windows_image_backups"

EXPECTED_COUNT=3

export SRC DST LOG_FILE

# ----------------------------
# Libraries
#
# Initialize the framework and load the
# backup operations required by this workflow.
# ----------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


# Load the framework bootstrap process.
# This initializes the core libraries,
# logging, timers, configuration, and
# execution environment.
source "$SCRIPT_ROOT/lib/core/bootstrap.sh"
bootstrap_init

# Load only the backup libraries required
# for this workflow.
source "$BACKUP_LIB_DIR/stamp_backups.sh"
source "$BACKUP_LIB_DIR/copy_backups.sh"



# Verify source and destination paths,
# available disk space, and other
# environmental requirements before
# any backup operations begin.
preflight_validate "$SRC" "$DST"



# ----------------------------
# Workflow
#
# This example:
# 1. Stamps non-dated backup folders into YYYYMMDD_FolderName format.
# 2. Copies the discovered backup folders to the secondary storage location.
#
# The driver controls sequence only.
# Operational behavior is handled by shared libraries.
# ----------------------------
run_job() {
    log_event "INFO" "START" "script" "0" "SUCCESS" "starting backup workflow"
    log_event "INFO" "MODE" "script" "0" "SUCCESS" "EXECUTION_MODE=$EXECUTION_MODE"

    log_event "INFO" "STAMP" "$SRC" "0" "START" "starting backup stamp"

    stamp_backups "$SRC" "$EXPECTED_COUNT"
    local rc=$?

    case "$rc" in
        0)
            ;;
        2)
            # Return code 2 means there was no non-dated folders to stamp.
            # This is treated as a successful no-op, not a failure.
            log_event "INFO" "SUMMARY" "workflow" "STAMP=SKIPPED COPY=NOT_RUN" "SUCCESS" "no new backup to process"
            return 0
            ;;
        *)
            log_event "ERROR" "SUMMARY" "workflow" "STAMP=FAIL COPY=NOT_RUN" "FAIL" "workflow aborted"
            return "$rc"
            ;;
    esac

    log_event "INFO" "COPY" "$DST" "0" "START" "starting backup copy"

    copy_backups "$SRC" "$DST" "non_date"
    rc=$?

    if [ "$rc" -eq 0 ]; then
        log_event "INFO" "SUMMARY" "workflow" "STAMP=SUCCESS COPY=SUCCESS" "SUCCESS" "backup workflow complete"
    else
        log_event "ERROR" "SUMMARY" "workflow" "STAMP=SUCCESS COPY=FAIL" "FAIL" "backup workflow completed with failures"
    fi

    return "$rc"
}

# ----------------------------
# Locked Execution
#
# Acquire an execution lock to prevent
# multiple instances of this workflow
# from running simultaneously.
#
# If the lock is acquired, run_job()
# executes within the locked context.
# If another instance is already running,
# the workflow logs the failure and exits.
# ----------------------------
if ! with_lock "$LOCK_FILE" run_job; then
    log_event "ERROR" "LOCK" "$LOCK_FILE" "0" "FAIL" "could not acquire lock"
    exit 1
fi

# ----------------------------
# Runtime Summary
#
# Log total runtime.
# SCRIPT_START_TIME is initialized during bootstrap.
# ----------------------------
SCRIPT_DURATION=$(get_elapsed_duration "$SCRIPT_START_TIME")
log_event "INFO" "RUN_COMPLETE" "script" "$SCRIPT_DURATION" "SUCCESS" "finished"
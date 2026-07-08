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
SYSTEM_NAME="NAS-CLEAR"
SERVICE_NAME="TrimRetentionExample"
NODE_NAME="ExampleNAS"

export SYSTEM_NAME SERVICE_NAME NODE_NAME EXECUTION_MODE

# ----------------------------
# Config
#
# LOG_FILE controls where this workflow writes logs.
# LOCK_FILE prevents overlapping runs of the same job.
# ----------------------------
LOG_FILE="/mnt/logs/TrimRetentionExample/$(date +'%Y%m%d')_trim_retention.log"
LOCK_FILE="/tmp/trim_retention_example.lock"

# ----------------------------
# Paths / Retention
#
# SRC contains the backup folders to process.
# KEEP_DATES defines how many dated backup sets are retained.
# ----------------------------
SRC="/mnt/archive_storage/monthly_backups"
KEEP_DATES=5

export SRC LOG_FILE

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
source "$BACKUP_LIB_DIR/trim_backups.sh"

# Verify the source path before any
# retention cleanup operations begin.
preflight_validate_path "$SRC"

# ----------------------------
# Workflow
#
# This example:
# 1. Scans the source folder for dated backup sets.
# 2. Keeps the newest KEEP_DATES backup sets.
# 3. Removes older backup sets outside the retention window.
#
# The driver controls sequence only.
# Operational behavior is handled by
# the shared libraries.
# ----------------------------
run_job() {
    log_event "INFO" "START" "script" "0" "SUCCESS" "starting retention trim workflow"
    log_event "INFO" "MODE" "script" "0" "SUCCESS" "EXECUTION_MODE=$EXECUTION_MODE"

    # Execute the shared retention workflow.
    # Date discovery, retention selection,
    # deletion, DRY_RUN/LIVE behavior, and
    # logging are handled internally by trim_backups().
    trim_backups "$SRC" "$KEEP_DATES"
    local rc=$?

    if [ "$rc" -eq 0 ]; then
        log_event "INFO" "SUMMARY" "workflow" "TRIM=SUCCESS" "SUCCESS" "retention trim workflow complete"
    else
        log_event "ERROR" "SUMMARY" "workflow" "TRIM=FAIL" "FAIL" "retention trim workflow completed with failures"
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
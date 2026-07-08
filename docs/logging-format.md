## Logging Format Overview

Each workflow uses the `log_event` function to write structured log entries.

A script or library passes 6 arguments into `log_event`. The logging framework combines those arguments with runtime metadata from the driver script and bootstrap process to produce an 11-field log line.

## Arguments Passed to `log_event`

1. `LEVEL` - Severity of the event.
2. `ACTION` - Operation or workflow step being logged.
3. `TARGET` - File, folder, path, system, or workflow object being acted on.
4. `METRIC` - Count, duration, return code, or other useful context value.
5. `RESULT` - Outcome or state of the logged event.
6. `MESSAGE` - Human-readable detail about the event.

## Full Log Output

Each final log entry contains 11 pipe-delimited fields.

```
TIMESTAMP | RUN_ID | LEVEL | SYSTEM | SERVICE | NODE | ACTION | TARGET | METRIC | RESULT | MESSAGE

Field Reference
TIMESTAMP - UTC date and time when the event was logged.
RUN_ID - Unique identifier for a single script execution.
LEVEL - Severity of the event.
SYSTEM - System category passed from the driver script.
SERVICE - Service or workflow name passed from the driver script.
NODE - Node name passed from the driver script.
ACTION - Action taken during the logged event.
TARGET - Target of the logged event.
METRIC - Numeric or contextual value associated with the event.
RESULT - Outcome of the logged event.
MESSAGE - Human-readable detail about the event.
```


## Example Log Line

```
2026-06-19T18:50:13Z | 20260619T185013Z-30665 | INFO | NAS-MOVE | MoveWeeklyVMsExample | ExampleNAS | MOVE | 20260516_AppServerVM01 | 0 | SIMULATED | would move
```

This log entry shows that the MoveWeeklyVMsExample workflow identified the backup folder 20260516_AppServerVM01 for movement.

The workflow was running in DRY_RUN mode, so the operation was logged as SIMULATED and no filesystem changes were made.

If the workflow had been executed in LIVE mode, the backup folder would have been moved to its configured destination.


## Field Details

### TIMESTAMP

UTC date and time when the event was logged.

### RUN_ID

Unique identifier assigned to a specific workflow execution. All events generated during a single run share the same RUN_ID.

### LEVEL

Severity of the logged event. Used to quickly identify informational messages, warnings, and errors.

### SYSTEM

High-level category describing the workflow being executed.

Examples:
- NAS-COPY
- NAS-MOVE
- NAS-CLEAR

### SERVICE

Workflow or driver script name responsible for generating the event.

### NODE

System or NAS executing the workflow.

### ACTION

Specific operation being performed.

Examples:
- COPY
- MOVE
- SYNC
- DELETE
- VALIDATE
- DISCOVER

### TARGET

Object being acted upon.

Examples:
- Backup folder
- File path
- Lock file
- Workflow component

### METRIC

Optional numeric or contextual value associated with the event.

Examples:
- Folder counts
- Runtime values
- Return codes
- Retention counts

### RESULT

Outcome of the operation.

Examples:
- SUCCESS
- FAIL
- SIMULATED
- SKIPPED

### MESSAGE

Additional human-readable context describing the event.



## Common Actions

### Startup / Setup

- BOOT
- VALIDATE
- LOCK_CHECK
- LOCK_ACQUIRE
- START
- MODE

### Discovery

- DISCOVER
- SCAN

### Backup Operations

- STAMP
- RENAME
- COPY
- MOVE
- SYNC
- DELETE
- CLEAN
- RETENTION

### Completion

- SUMMARY
- RUN_COMPLETE
- LOCK_RELEASE


## Common Results
- START - Operation has begun.
- OK - Validation passed.
- SUCCESS - Operation completed successfully.
- FAIL - Operation failed.
- SIMULATED - DRY_RUN action that would have modified files but did not.
- SKIPPED - Workflow intentionally skipped a step.
- NO_CHANGE - Destination already matched the source, so no update was required.



## Reading a Workflow From Logs

A normal workflow should be readable from top to bottom:

- BOOT confirms framework initialization.
- VALIDATE confirms paths and system checks passed.
- LOCK_CHECK and LOCK_ACQUIRE confirm the job is not already running.
- START and MODE show the workflow began and whether it is DRY_RUN or LIVE.
- DISCOVER or SCAN shows what backup sets were found.
- COPY, MOVE, DELETE, RENAME, or RETENTION lines show the primary work being performed.
- SUMMARY shows operation totals.
- RUN_COMPLETE shows total runtime.
- LOCK_RELEASE confirms the lock was cleared.


## Sample Output Files

- `sample-output/copy_weekly_backups_example.log`
  - Demonstrates stamping non-dated backup folders and simulating copy operations.

- `sample-output/move_weekly_vms_example.log`
  - Demonstrates moving weekly VM backup sets into a monthly/archive location.

- `sample-output/trim_monthly_backups_example.log`
  - Demonstrates retention cleanup by keeping the newest backup sets and simulating deletion of older sets.
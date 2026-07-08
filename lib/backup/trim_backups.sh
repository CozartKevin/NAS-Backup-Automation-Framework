#!/bin/bash



# ----------------------------
# Dependencies
# ----------------------------

source "$BACKUP_LIB_DIR/backup_dates.sh"

# ----------------------------
# Trim Backup LIBRARY 
# Depends on:
# logging.sh (6-arg format) loaded by bootstrap.sh
# backup_Dates.sh loaded below
# ----------------------------

trim_backups() {
    local backup_dir="$1"
    local keep_dates="$2"

    # validate input
    [[ "$keep_dates" =~ ^[0-9]+$ ]] || return 2
    (( keep_dates > 0 )) || return 2
    if [ ! -d "$backup_dir" ]; then
        log_event "ERROR" "VALIDATE" "$backup_dir" "0" "FAIL" "directory missing"
        return 1
    fi

    log_event "INFO" "MODE" "$backup_dir" "0" "SUCCESS" "mode=${EXECUTION_MODE}"
    log_event "INFO" "SCAN" "$backup_dir" "0" "SUCCESS" "directory scan"

   

local unique_dates delete_count delete_dates

unique_dates=$(get_unique_dates "$backup_dir")

if [ -z "$unique_dates" ]; then
    log_event "INFO" "DISCOVER" "$backup_dir" "1" "SKIP" "no backups found"
    return 1
fi


local total_dates
total_dates=$(echo "$unique_dates" | wc -l | tr -d ' ')

log_event "INFO" "DISCOVER" "dates_count" "$total_dates" "SUCCESS" "backup sets found"
log_event "INFO" "DISCOVER" "dates_list" "$total_dates" "SUCCESS" "$(echo "$unique_dates" | paste -sd ';' -)"

if (( total_dates <= keep_dates )); then
    log_event "INFO" "RETENTION" "dates" "$total_dates" "SUCCESS" "no deletion required"
    return 0
fi

    delete_count=$((total_dates - keep_dates))
    delete_dates=$(echo "$unique_dates" | head -n "$delete_count")

    log_event "INFO" "RETENTION" "keep" "$keep_dates" "SUCCESS" "retention applied"
    log_event "INFO" "RETENTION" "delete_count" "$delete_count" "SUCCESS" "scheduled deletions"

    local success_count=0 
    local failure_count=0

while IFS= read -r backup_date; do
    log_event "INFO" "DELETE" "$backup_date" "0" "START" "processing batch"

    while IFS= read -r folder; do
        [ -z "$folder" ] && continue

        folder_name=$(basename "$folder")

      
        execute_delete "$folder" "$folder_name"
        local rc=$?
        
        case "$rc" in
            0)
                success_count=$((success_count + 1))
                ;;
            *)
                failure_count=$((failure_count + 1))
                ;;
        esac

    done < <(
        find "$backup_dir" -mindepth 1 -maxdepth 1 -type d -name "${backup_date}_*"
    )

done <<< "$delete_dates"

    if [ "$failure_count" -eq 0 ]; then

    log_event "INFO" "SUMMARY" "batch" "$success_count/$failure_count" "SUCCESS" "cleanup complete"
    return 0
else

    log_event "ERROR" "SUMMARY" "batch" "$success_count/$failure_count" "FAIL" "cleanup completed with failures"
    return 1
fi

 
}

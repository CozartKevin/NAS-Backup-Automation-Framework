#!/bin/bash

: "${SRC:?SRC not set}"
: "${DST:?DST not set}"
: "${EXECUTION_MODE:?EXECUTION_MODE not set}" 


source "$BACKUP_LIB_DIR/backup_dates.sh"



# ----------------------------
# Move Backup LIBRARY 
# Depends on:
# logging.sh (6-arg format) loaded by bootstrap.sh
# backup_Dates.sh loaded above
# ----------------------------



move_backups(){

    local src="$1"
    local dst="$2"

# --- Discover folders for oldest backup date ---

local oldest_date_prefix
oldest_date_prefix=$(get_date_by_order "$src" "oldest")

if [ -z "$oldest_date_prefix" ]; then
    log_event "INFO" "DISCOVER" "$src" "1" "SKIP" "no backup dates found"
    return 1
fi

local folders_to_move
folders_to_move=()

while IFS= read -r folder; do
    [ -n "$folder" ] && folders_to_move+=("$folder")
done < <(
    get_folders_for_date "$src" "$oldest_date_prefix"
)

if [ "${#folders_to_move[@]}" -eq 0 ]; then
    log_event "ERROR" "VALIDATE" "$src" "0" "FAIL" "No date-prefixed folders in $src"
    return 1
fi

local folder_list
folder_list=$(printf "%s;" "${folders_to_move[@]}")
folder_list=${folder_list%;}   # removes trailing ;

log_event "INFO" "DISCOVER" "folder_count" "${#folders_to_move[@]}" "SUCCESS" "folder discovery complete"
log_event "INFO" "DISCOVER" "folder_list" "${#folders_to_move[@]}" "SUCCESS" "$folder_list"


# --- Move execution loop ---
local moved_count=0
local failed_folders=()

for folderName in "${folders_to_move[@]}"; do

    local src_path="$src/$folderName"
    local dst_path="$dst/$folderName"

    log_event "INFO" "MOVE" "$folderName" "0" "START" "processing"
    

    execute_move "$src_path" "$dst_path" "$folderName"

local rc=$?

case "$rc" in
    0)
        moved_count=$((moved_count+1))

        execute_clean_dir "$src_path" "$folderName"
        local clean_rc=$?

        if [ "$clean_rc" -ne 0 ]; then
            failed_folders+=("$folderName:cleanup:$clean_rc")
        fi
        ;;

    *)
        failed_folders+=("$folderName:move:$rc")
        ;;
esac

done


if [ "${#failed_folders[@]}" -eq 0 ]; then

    log_event "INFO" "SUMMARY" "batch" "$moved_count/${#failed_folders[@]}" "SUCCESS" "move complete"
    return 0
else

    log_event "ERROR" "SUMMARY" "batch" "$moved_count/${#failed_folders[@]}" "FAIL" "move completed with failures"
    return 1
fi

}

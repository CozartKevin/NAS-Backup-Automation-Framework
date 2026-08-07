#!/bin/bash


: "${SRC:?SRC not set}"
: "${DST:?DST not set}"
: "${EXECUTION_MODE:?EXECUTION_MODE not set}" 




source "$BACKUP_LIB_DIR/backup_dates.sh"

# ----------------------------
# Copy Backup LIBRARY 
# Depends on:
# logging.sh (6-arg format) loaded by bootstrap.sh
# backup_Dates.sh loaded above
# ----------------------------

copy_backups() {

    local src="$1"
    local dst="$2"
    local mode="${3:-non_date}"


    local folders_to_copy
    folders_to_copy=() 

    case "$mode" in

        newest|oldest)

            local date_prefix

            date_prefix=$(get_date_by_order "$src" "$mode")


            if [ -z "$date_prefix" ]; then
                log_event "INFO" "DISCOVER" "$src" "1" "SKIP" "no backup dates found"
                return 1
            fi


            while IFS= read -r folder; do
                [ -n "$folder" ] && folders_to_copy+=("$folder")
            done < <(
                get_folders_for_date "$src" "$date_prefix"
            )

            ;;


        non_date)

            while IFS= read -r folder; do
                [ -n "$folder" ] && folders_to_copy+=("$folder")
            done < <(
                list_non_date_folders "$src"
            )

            ;;


        *)
            log_event "ERROR" "VALIDATE" "$mode" "0" "FAIL" "invalid copy mode"
            return 2
            ;;

    esac

    if [ "${#folders_to_copy[@]}" -eq 0 ]; then
    log_event "ERROR" "VALIDATE" "$src" "0" "FAIL" "No folders found for mode=$mode"
    return 1
fi

    local folder_list
    folder_list=$(printf "%s;" "${folders_to_copy[@]}")
    folder_list=${folder_list%;}   # removes trailing ;

    log_event "INFO" "DISCOVER" "folder_count" "${#folders_to_copy[@]}" "SUCCESS" "folder discovery complete mode=$mode"
    log_event "INFO" "DISCOVER" "folder_list" "${#folders_to_copy[@]}" "SUCCESS" "$folder_list"


    # --- execution tracking ---
   # --- execution tracking ---
local copied_count=0
local synced_count=0
local failed_folders=()

# --- main loop ---
for folderName in "${folders_to_copy[@]}"; do

    local src_path="$src/$folderName"
    local dst_path="$dst/$folderName"
    local rc

    # log_event "INFO" "COPY" "$folderName" "0" "START" "processing"

    if [[ -d "$dst_path" ]]; then
        execute_sync "$src_path" "$dst_path" "$folderName"
        rc=$?

        case "$rc" in
            0)
                synced_count=$((synced_count+1))
                ;;
            *)
                failed_folders+=("$folderName:sync:$rc")
                ;;
        esac
    else
        execute_copy "$src_path" "$dst_path" "$folderName"
        rc=$?

        case "$rc" in
            0)
                copied_count=$((copied_count+1))
                ;;
            *)
                failed_folders+=("$folderName:copy:$rc")
                ;;
        esac
    fi

done


if [ "${#failed_folders[@]}" -eq 0 ]; then

    log_event "INFO" "SUMMARY" "batch" "$copied_count/${#failed_folders[@]}" "SUCCESS" "copy complete mode=$mode"
    return 0
else

    log_event "ERROR" "SUMMARY" "batch" "$copied_count/${#failed_folders[@]}" "FAIL" "copy completed with failures mode=$mode"
    return 1
fi


}

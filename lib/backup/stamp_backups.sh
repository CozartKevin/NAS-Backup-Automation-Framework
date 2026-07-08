#!/bin/bash

: "${BACKUP_LIB_DIR:?bootstrap not initialized}"
: "${EXECUTION_MODE:?execution mode not set}"

# ----------------------------
# Dependencies
# ----------------------------

source "$BACKUP_LIB_DIR/backup_dates.sh"


# ----------------------------
# Stamp Backup Library
#
# Purpose:
# Rename non-dated backup folders
# into YYYYMMDD_FolderName format
#
# Depends on:
# logging.sh loaded by bootstrap.sh
# backup_dates.sh
# execution.sh
#
# Example:
# stamp_backups "/volume5/NASDrive5/WindowsImageBackup" 1
# ----------------------------


stamp_backups() {

    local backup_dir="$1"
    local expected_count="${2:-}"


    if [ ! -d "$backup_dir" ]; then
        log_event "ERROR" "VALIDATE" "$backup_dir" "0" "FAIL" "directory missing"
        return 1
    fi


    local date_prefix
    date_prefix=$(date +"%Y%m%d")


    local folders_to_stamp
    folders_to_stamp=()


    while IFS= read -r folder; do
        [ -n "$folder" ] && folders_to_stamp+=("$folder")
    done < <(
        list_non_date_folders "$backup_dir"
    )

    if [ "${#folders_to_stamp[@]}" -eq 0 ]; then
        log_event "INFO" "STAMP" "$backup_dir" "0" "SKIP" "no non-dated folders found"
        return 2
    fi


    local folder_list
    folder_list=$(printf "%s;" "${folders_to_stamp[@]}")
    folder_list=${folder_list%;}

    log_event "INFO" "DISCOVER" "folder_count" "${#folders_to_stamp[@]}" "SUCCESS" "folder discovery complete mode=non_date"
    log_event "INFO" "DISCOVER" "folder_list" "${#folders_to_stamp[@]}" "SUCCESS" "$folder_list"


    if [ "$expected_count" -lt 0 ]; then

        log_event "ERROR" "STAMP_VALIDATE" "$backup_dir" "$expected_count" "FAIL" "invalid expected_count"

        return 1

    fi


   if [ "$expected_count" -gt 0 ]; then

        if [ "${#folders_to_stamp[@]}" -ne "$expected_count" ]; then

            log_event "WARN" "STAMP_VALIDATE" "$backup_dir" "${#folders_to_stamp[@]}" "MISMATCH" "expected=$expected_count actual=${#folders_to_stamp[@]}"

        else

            log_event "INFO" "STAMP_VALIDATE" "$backup_dir" "${#folders_to_stamp[@]}" "OK" "expected=$expected_count actual=${#folders_to_stamp[@]}"

        fi

    fi

    

    local stamped_count=0
    local failed_count=0
    local rc

    for folder in "${folders_to_stamp[@]}"; do

        local old_path="$backup_dir/$folder"
        local new_path="$backup_dir/${date_prefix}_${folder}"


        log_event "INFO" "STAMP" "$folder" "0" "START" "renaming"


        if [ -e "$new_path" ]; then

            log_event "ERROR" "STAMP" "$folder" "0" "FAIL" "destination exists"

            failed_count=$((failed_count + 1))

            continue

        fi


        execute_rename "$old_path" "$new_path" "$folder"

        rc=$?

        if [ "$rc" -eq 0 ]; then

            if [ "$EXECUTION_MODE" = "LIVE" ] && [ ! -d "$new_path" ]; then

                    log_event "ERROR" "STAMP" "$new_path" "0" "FAIL" "rename verification failed"
                    failed_count=$((failed_count + 1))

                else

                    stamped_count=$((stamped_count + 1))

                fi

        else
            log_event "ERROR" "STAMP" "$folder" "$rc" "FAIL" "rename failed"
            failed_count=$((failed_count + 1))

        fi

    done


     if [ "$failed_count" -eq 0 ]; then

        log_event "INFO" "SUMMARY" "stamp" "$stamped_count/$failed_count" "SUCCESS" "stamp complete"
        return 0

    else

        log_event "ERROR" "SUMMARY" "stamp" "$stamped_count/$failed_count" "FAIL" "stamp completed with failures"
        return 1

    fi

}

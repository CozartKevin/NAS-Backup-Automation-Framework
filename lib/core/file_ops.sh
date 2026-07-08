#!/bin/bash


# Return Codes
#
# 0 = Success
# 1 = Operation failed
# 2 = Invalid input / validation failure

file_ops_copy() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || return 2

    if rsync -aH --no-xattrs --no-acls --partial --inplace "$src/" "$dst/"; then
        
        if [ "$(find "$dst" -mindepth 1 -print -quit 2>/dev/null)" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

file_ops_move() {
    local src="$1"
    local dst="$2"
    
    [[ -d "$src" ]] || return 2

    if rsync -aH --remove-source-files --no-xattrs --no-acls --partial "$src/" "$dst/"; then
        
        if [ "$(find "$dst" -mindepth 1 -print -quit 2>/dev/null)" ]; then
            return 0
        else
            return 1
        fi

    else
        return 1
    fi
}

file_ops_delete() {
    local target="$1"

    [[ -n "$target" ]] || return 2
    [[ "$target" != "/" ]] || return 2
    [[ "$target" != "." ]] || return 2
    [[ "$target" != ".." ]] || return 2
    [[ -d "$target" ]] || return 2

    if rm -rf "$target"; then
        return 0
    else
        return 1
    fi
}

file_ops_sync() {
    local src_path="$1"
    local dst_path="$2"

    [[ -d "$src_path" ]] || return 2

    mkdir -p "$dst_path"

    if [[ "$EXECUTION_MODE" == "DRY_RUN" ]]; then
        rsync -a --dry-run --itemize-changes "$src_path/" "$dst_path/"
    else
        rsync -a --itemize-changes "$src_path/" "$dst_path/"
    fi
}



file_ops_verify_directory_match(){
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || return 2
    [[ -d "$dst" ]] || return 2

    if diff -rq "$src" "$dst"; then
        return 0
    else   
        return 1
    fi
}

file_ops_remove_empty_dir_tree() {
    local path="$1"

    [[ -d "$path" ]] || return 2

    # If any files remain, do not remove anything.
    if find "$path" -type f -print -quit | grep -q .; then
        return 1
    fi

    # Only empty directories remain, so remove the tree.
    find "$path" -depth -type d -empty -delete 2>/dev/null

    [[ ! -d "$path" ]] && return 0
    return 1
}
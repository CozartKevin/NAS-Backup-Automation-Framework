#!/bin/bash

# ----------------------------
# Timer LIBRARY (CLEAN CONTRACT)
# 
# ----------------------------

start_timer() {
    date +%s
}

stop_timer() {
    local start="$1"
    echo $(( $(date +%s) - start ))
}

format_duration() {
    local total="$1"

    printf '%02d:%02d:%02d\n' \
        $((total/3600)) \
        $(((total%3600)/60)) \
        $((total%60))
}

get_elapsed_duration() {
    local start="$1"

    format_duration "$(stop_timer "$start")"
}
#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract workspace info
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
dir_name="${current_dir##*/}"
branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)

# Extract context window info
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Extract session duration
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Function to generate a bar graph from a percentage (0-100)
generate_bar_graph() {
    local pct=$1
    local bar_width=15
    local pct_int=${pct%.*}

    # Clamp to 0-100
    [ "$pct_int" -lt 0 ] 2>/dev/null && pct_int=0
    [ "$pct_int" -gt 100 ] 2>/dev/null && pct_int=100

    local filled=$((pct_int * bar_width / 100))
    local empty=$((bar_width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done

    echo "$bar"
}

# Fetch 5-hour rolling window utilization (cached for 30s)
USAGE_CACHE="/tmp/claude-statusline-usage-cache"
CACHE_MAX_AGE=30

# Refresh the cached usage API response if older than CACHE_MAX_AGE
refresh_usage_cache() {
    local cache_stale=1
    if [ -f "$USAGE_CACHE" ]; then
        local cache_age=$(( $(date +%s) - $(stat -c %Y "$USAGE_CACHE" 2>/dev/null || echo 0) ))
        [ "$cache_age" -le "$CACHE_MAX_AGE" ] && cache_stale=0
    fi

    if [ "$cache_stale" -eq 1 ]; then
        local token
        token=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            local resp
            resp=$(curl -s --max-time 3 -X GET \
                "https://api.anthropic.com/api/oauth/usage" \
                -H "Authorization: Bearer $token" \
                -H "Accept: application/json" \
                -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)
            if [ -n "$resp" ]; then
                echo "$resp" > "$USAGE_CACHE"
            fi
        fi
    fi

}

# Read a window's utilization (e.g. five_hour, seven_day) from the cache
get_utilization() {
    [ -f "$USAGE_CACHE" ] && jq -r ".$1.utilization // empty" "$USAGE_CACHE" 2>/dev/null
}

# Read a window's reset time (ISO 8601) from the cache
get_resets_at() {
    [ -f "$USAGE_CACHE" ] && jq -r ".$1.resets_at // empty" "$USAGE_CACHE" 2>/dev/null
}

# Format an ISO 8601 reset time in local time: <iso> <date format>
format_reset() {
    [ -n "$1" ] && [ "$1" != "null" ] && LC_TIME=C date -d "$1" +"$2" 2>/dev/null
}

refresh_usage_cache
five_hour_pct=$(get_utilization five_hour)
seven_day_pct=$(get_utilization seven_day)
five_hour_reset=$(format_reset "$(get_resets_at five_hour)" '%H:%M')
seven_day_reset=$(format_reset "$(get_resets_at seven_day)" '%a %H:%M')

# ANSI color helpers
color_for_pct() {
    local pct_int=${1%.*}
    if [ "$pct_int" -ge 90 ] 2>/dev/null; then
        printf '\033[31m'  # red
    elif [ "$pct_int" -ge 75 ] 2>/dev/null; then
        printf '\033[33m'  # yellow
    fi
}
RESET=$'\033[0m'

# Build status line parts
status_parts=()

# Path and git branch
if [ -n "$dir_name" ]; then
    path_part="$dir_name"
    [ -n "$branch" ] && path_part="$path_part ($branch)"
    status_parts+=("$path_part")
fi

# Context window bar (handle null/empty at session start)
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    bar=$(generate_bar_graph "$used_pct")
    ctx_color=$(color_for_pct "$used_pct")
    if [ -n "$ctx_color" ]; then
        status_parts+=("${ctx_color}Context: ${bar} ${used_pct}%${RESET}")
    else
        status_parts+=("Context: ${bar} ${used_pct}%")
    fi
else
    bar=$(generate_bar_graph 0)
    status_parts+=("Context: ${bar}")
fi

# Rate limit bar: add_limit_part <label> <pct> [reset time]
add_limit_part() {
    local label=$1 pct=$2 reset=$3
    local reset_suffix=""
    [ -n "$reset" ] && reset_suffix=" (${reset})"
    if [ -n "$pct" ] && [ "$pct" != "null" ]; then
        local pct_int=${pct%.*}
        local lbar color
        lbar=$(generate_bar_graph "$pct_int")
        color=$(color_for_pct "$pct_int")
        if [ -n "$color" ]; then
            status_parts+=("${color}${label}: ${lbar} ${pct_int}%${reset_suffix}${RESET}")
        else
            status_parts+=("${label}: ${lbar} ${pct_int}%${reset_suffix}")
        fi
    else
        status_parts+=("${label}: $(generate_bar_graph 0)")
    fi
}

add_limit_part "5h limit" "$five_hour_pct" "$five_hour_reset"
add_limit_part "Weekly limit" "$seven_day_pct" "$seven_day_reset"

# Current session: duration
duration_sec=$((duration_ms / 1000))
mins=$((duration_sec / 60))
secs=$((duration_sec % 60))
status_parts+=("${mins}m ${secs}s")

# Join all parts with pipe separators
result=""
for part in "${status_parts[@]}"; do
    if [ -n "$result" ]; then
        result="$result | $part"
    else
        result="$part"
    fi
done
printf "%s" "$result"

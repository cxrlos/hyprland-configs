#!/usr/bin/env bash
# JSON for the bar's system icon and metrics dropdown: CPU/RAM/GPU usage and the
# pending official-repo update count. Sizes are in GiB.
set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/system-status"
readonly UPDATES_TTL=1800
mkdir -p "$STATE_DIR"

cpu_percent() {
    local _ user nice system idle iowait irq softirq steal total busy
    read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    busy=$((total - idle - iowait))

    local prev_total=0 prev_busy=0
    [[ -f $STATE_DIR/cpu ]] && read -r prev_total prev_busy <"$STATE_DIR/cpu"
    echo "$total $busy" >"$STATE_DIR/cpu"

    local d_total=$((total - prev_total))
    if ((d_total > 0)); then
        echo $(((busy - prev_busy) * 100 / d_total))
    else
        echo 0
    fi
}

memory_json() {
    awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2}
        END {printf "{\"used\": %.1f, \"total\": %.1f}", (t-a)/1048576, t/1048576}' /proc/meminfo
}

gpu_json() {
    local dev
    for dev in /sys/class/drm/card*/device; do
        [[ -f $dev/gpu_busy_percent ]] || continue
        awk -v busy="$(<"$dev/gpu_busy_percent")" \
            -v used="$(<"$dev/mem_info_vram_used")" \
            -v total="$(<"$dev/mem_info_vram_total")" \
            'BEGIN {printf "{\"busy\": %d, \"vramUsed\": %.1f, \"vramTotal\": %.0f}", busy, used/1073741824, total/1073741824}'
        return
    done
    echo null
}

# checkupdates syncs a temp copy of the pacman db, so refresh it in the background
# at most every UPDATES_TTL seconds and read the cached count in between.
updates_count() {
    local cache=$STATE_DIR/updates
    if [[ ! -f $cache ]] || (($(date +%s) - $(stat -c %Y "$cache") > UPDATES_TTL)); then
        touch "$cache"
        (checkupdates 2>/dev/null | wc -l >"$cache.tmp" && mv "$cache.tmp" "$cache") &
    fi
    local n
    n=$(<"$cache")
    echo "${n:-0}"
}

jq -nc \
    --argjson cpu "$(cpu_percent)" \
    --argjson memory "$(memory_json)" \
    --argjson gpu "$(gpu_json)" \
    --argjson updates "$(updates_count)" \
    '{cpu: $cpu, memory: $memory, gpu: $gpu, updates: $updates}'

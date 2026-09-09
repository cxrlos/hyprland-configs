#!/usr/bin/env bash
# Instant read of AMD GPU & VRAM metrics via sysfs
set -euo pipefail

gpu_path="/sys/class/drm/card1/device"
if [[ ! -d "$gpu_path" ]]; then
    gpu_path="/sys/class/drm/card0/device"
fi

if [[ -f "$gpu_path/gpu_busy_percent" ]]; then
    busy=$(cat "$gpu_path/gpu_busy_percent")
    vram_used=$(cat "$gpu_path/mem_info_vram_used" 2>/dev/null || echo 0)
    vram_mb=$((vram_used / 1024 / 1024))
    vram_gb=$(awk "BEGIN {printf \"%.1f\", $vram_mb / 1024}")
    printf '{"text": "󰢮 %s%% %sG", "tooltip": "GPU Core: %s%%\nVRAM Used: %s MB", "class": "gpu"}\n' "$busy" "$vram_gb" "$busy" "$vram_mb"
else
    printf '{"text": "󰢮 N/A", "tooltip": "GPU sysfs path unavailable", "class": "gpu"}\n'
fi

#!/usr/bin/env bash
# Exits 0 only when running on battery: at least one mains adapter exists and none is
# online. Desktops (no adapter) and plugged-in laptops exit 1, so hypridle's battery
# listeners do nothing there.
set -euo pipefail
shopt -s nullglob

found=0
for supply in /sys/class/power_supply/*; do
    [[ $(<"$supply/type") == Mains ]] || continue
    found=1
    [[ $(<"$supply/online") == 1 ]] && exit 1
done

((found))

#!/usr/bin/env bash
# Clipboard history for the Quickshell clipboard panel, backed by cliphist.
#   clipboard.sh list        JSON array of the newest entries; images get a cached preview file
#   clipboard.sh copy <id>   put that entry back on the clipboard
set -euo pipefail

readonly LIMIT=60
readonly PREVIEWS="${XDG_RUNTIME_DIR:-/tmp}/clipboard-previews"

case "${1:-}" in
    list)
        mkdir -p "$PREVIEWS"
        cliphist list | head -n "$LIMIT" | while IFS=$'\t' read -r id text; do
            image=""
            if [[ $text == "[[ binary data "* ]]; then
                image="$PREVIEWS/$id"
                [[ -s $image ]] || cliphist decode "$id" >"$image"
            fi
            jq -nc --arg id "$id" --arg text "$text" --arg image "$image" \
                '{id: $id, text: $text, image: $image}'
        done | jq -sc .
        ;;
    copy)
        cliphist decode "$2" | wl-copy
        ;;
    *)
        echo "usage: ${0##*/} list|copy <id>" >&2
        exit 2
        ;;
esac

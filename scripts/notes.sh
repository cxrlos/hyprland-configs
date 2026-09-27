#!/usr/bin/env bash
# Notes in every Obsidian vault as JSON [{vault, file, title, folder}] for the launcher;
# `file` is vault-relative without .md, the form obsidian://open expects.
set -euo pipefail

vaults="$HOME/.config/obsidian/obsidian.json"
[[ -f "$vaults" ]] || { echo '[]'; exit 0; }

jq -r '.vaults[].path' "$vaults" | while IFS= read -r vault; do
    [[ -d "$vault" ]] || continue
    find "$vault" -mindepth 1 -name '.*' -prune -o -name node_modules -prune -o -type f -name '*.md' -printf '%P\n' |
        jq -R --arg vault "$(basename "$vault")" '
            sub("\\.md$"; "") as $file
            | ($file | split("/")) as $parts
            | {vault: $vault, file: $file, title: $parts[-1], folder: ($parts[:-1] | join("/"))}'
done | jq -s 'sort_by(.title | ascii_downcase)'

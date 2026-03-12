#!/usr/bin/env bash
# Launch Firefox with "Sustainlabs Ai" profile by resolving path from profiles.ini
# (avoids -P name matching issues that can show the Profile Manager)
set -e
PROFILES_INI="$HOME/.mozilla/firefox/profiles.ini"
if [[ ! -f "$PROFILES_INI" ]]; then
  exec firefox -P "Sustainlabs Ai"
fi

# Find Path= for the profile whose Name= contains "Sustainlabs"
PROFILE_PATH=$(awk '
  /^\[Profile/ {
    if (name ~ /Sustainlabs/ && path != "") { print path; exit }
    name = ""; path = ""
    next
  }
  /^Name=/ { sub(/^Name=/, ""); name = $0; next }
  /^Path=/ { sub(/^Path=/, ""); path = $0; next }
  END { if (name ~ /Sustainlabs/ && path != "") print path }
' "$PROFILES_INI")

if [[ -n "$PROFILE_PATH" ]]; then
  exec firefox -profile "$HOME/.mozilla/firefox/$PROFILE_PATH"
else
  exec firefox -P "Sustainlabs Ai"
fi

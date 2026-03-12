#!/usr/bin/env bash
# Launch Firefox default-release by reading path from profiles.ini (parseable, no hardcoded path).
set -e
for INI in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/profiles.ini" "$HOME/.mozilla/firefox/profiles.ini"; do
  [[ -f "$INI" ]] || continue
  MOZ_DIR=$(dirname "$INI")
  # Path= for the profile whose Name=default-release (same [Profile*] block)
  PROFILE_PATH=$(awk '
    /^\[Profile/ { path = ""; name = "" }
    /^Name=/ { sub(/^Name=/, ""); name = $0 }
    /^Path=/ { sub(/^Path=/, ""); path = $0; if (name == "default-release") { print path; exit } }
  ' "$INI")
  if [[ -n "$PROFILE_PATH" ]]; then
    hyprctl dispatch workspace 2
    exec firefox --profile "$MOZ_DIR/$PROFILE_PATH" --profiles-activate
  fi
done
echo "firefox-p1: no profile 'default-release' in profiles.ini" >&2
exit 1

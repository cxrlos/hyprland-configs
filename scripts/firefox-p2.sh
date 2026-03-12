#!/usr/bin/env bash
# Launch Firefox "Profile 1" by reading path from profiles.ini (parseable, no hardcoded path).
set -e
for INI in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/profiles.ini" "$HOME/.mozilla/firefox/profiles.ini"; do
  [[ -f "$INI" ]] || continue
  MOZ_DIR=$(dirname "$INI")
  # Path= line for the profile whose path contains "Profile 1"
  PROFILE_PATH=$(awk -F= '/^Path=/ && $2 ~ /Profile 1/ { print $2; exit }' "$INI")
  if [[ -n "$PROFILE_PATH" ]]; then
    hyprctl dispatch workspace 2
    exec firefox --profile "$MOZ_DIR/$PROFILE_PATH" --profiles-activate
  fi
done
echo "firefox-p2: no profile with 'Profile 1' in profiles.ini" >&2
exit 1

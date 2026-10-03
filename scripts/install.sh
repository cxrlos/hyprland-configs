#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

info()    { printf "%s\n" "${BLUE}→${NC} $*"; }
success() { printf "%s\n" "${GREEN}✓${NC} $*"; }
warn()    { printf "%s\n" "${YELLOW}!${NC} $*"; }
skip()    { printf "%s\n" "${DIM}–${NC} $* ${DIM}(not yet created)${NC}"; }
die()     { printf "%s\n" "${RED}✗${NC} $*" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(grep -m1 vendor_id /proc/cpuinfo)" in
    *GenuineIntel*) UCODE=intel-ucode ;;
    *AuthenticAMD*) UCODE=amd-ucode ;;
    *)              UCODE="" ;;
esac
# A battery means laptop: backlight, battery and power-profile support get installed.
IS_LAPTOP=false
compgen -G "/sys/class/power_supply/BAT*" >/dev/null && IS_LAPTOP=true
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

# ── Arch-only ──────────────────────────────────────────────────────────────────

[[ -f /etc/arch-release ]] || die "This installer targets Arch Linux only."

printf "\n%s\n\n" "${BOLD}Hyprland config installer  [arch]${NC}"

# ── Package managers ───────────────────────────────────────────────────────────

_ensure_yay() {
    if command -v yay &>/dev/null; then
        success "yay $(yay --version | head -1)"
        return 0
    fi
    warn "yay (AUR helper) not found"
    read -r -p "  Install yay? Required for AUR packages. [y/N] " yn
    [[ "$yn" =~ ^[yY]$ ]] || { warn "Skipping AUR packages"; return 1; }
    info "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si)
    rm -rf "$tmp"
    success "yay installed"
}

# ── Dependencies ───────────────────────────────────────────────────────────────

_install_deps() {
    # Full upgrade, not a bare -Sy: partial upgrades are unsupported on Arch and
    # can break dependency resolution.
    info "Updating system and syncing package database..."
    sudo pacman -Syu --noconfirm

    local pacman_deps=(
        hyprland hyprlock hypridle hyprpaper
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        quickshell swaync
        wl-clipboard cliphist unicode-emoji
        thunar
        grim slurp
        libnotify
        pipewire wireplumber
        bluez bluez-utils btop
        networkmanager
        polkit-gnome greetd greetd-regreet cage playerctl pavucontrol
        papirus-icon-theme
        qt5-wayland qt6-wayland
        gamemode lib32-gamemode
        inter-font
        wf-recorder pacman-contrib jq imagemagick
        nm-connection-editor satty hyprpicker obsidian
        python-yaml python-icalendar python-recurring-ical-events
    )

    [[ -n "$UCODE" ]] && pacman_deps+=("$UCODE")
    $IS_LAPTOP && pacman_deps+=(brightnessctl upower power-profiles-daemon)

    for dep in "${pacman_deps[@]}"; do
        if pacman -Qi "$dep" &>/dev/null; then
            success "$dep"
        else
            info "Installing $dep..."
            sudo pacman -S --noconfirm "$dep"
        fi
    done

    local aur_deps=(
        grimblast-git
        waypaper
        bibata-cursor-theme-bin
        ttf-apple-emoji
        ttf-material-symbols-variable-git
        zen-browser-bin
        gcalcli
    )

    if _ensure_yay; then
        for dep in "${aur_deps[@]}"; do
            if yay -Qi "$dep" &>/dev/null; then
                success "$dep  (AUR)"
            else
                info "Installing $dep  (AUR)..."
                yay -S --noconfirm "$dep"
            fi
        done
    else
        warn "Skipped AUR packages: ${aur_deps[*]}"
        warn "  Install manually: yay -S ${aur_deps[*]}"
    fi
}

_install_deps

# ── Backup helper ──────────────────────────────────────────────────────────────

_backup() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0
    local backup="${target}.bak.${TIMESTAMP}"
    mv "$target" "$backup"
    info "Backed up $(basename "$target") → $(basename "$backup")"
}

_backup_sudo() {
    local target="$1"
    sudo test -e "$target" || return 0
    local backup="${target}.bak.${TIMESTAMP}"
    sudo cp "$target" "$backup"
    info "Backed up $(basename "$target") → $(basename "$backup")"
}

# ── Symlink helper ─────────────────────────────────────────────────────────────

_link() {
    local src="$1" dst="$2"
    if [[ ! -e "$src" ]]; then
        skip "$dst"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    _backup "$dst"
    ln -sf "$src" "$dst"
    success "Symlinked: $dst → $src"
}

# ── Symlinks ───────────────────────────────────────────────────────────────────

printf "\n%s\n" "${BOLD}Linking configs...${NC}"

_link "$REPO_DIR/hypr"                         "$HOME/.config/hypr"
_link "$REPO_DIR/quickshell"                   "$HOME/.config/quickshell"
_link "$REPO_DIR/swaync"                       "$HOME/.config/swaync"
_link "$REPO_DIR/waypaper"                     "$HOME/.config/waypaper"
_link "$REPO_DIR/thunar"                       "$HOME/.config/Thunar"
_link "$REPO_DIR/scripts"                      "$HOME/.config/scripts"
_link "$REPO_DIR/fontconfig"                   "$HOME/.config/fontconfig"
_link "$REPO_DIR/gamemode.ini"                  "$HOME/.config/gamemode.ini"

# screenshot + steam (resolution fix) exposed in PATH
mkdir -p "$HOME/.local/bin"
_link "$REPO_DIR/scripts/screenshot.sh"        "$HOME/.local/bin/screenshot"
_link "$REPO_DIR/scripts/steam.sh"             "$HOME/.local/bin/steam"

# ── Zen theme (linked into Zen's default profile) ─────────────────────────────

# A fresh install has no profile until Zen's first start, so a headless run creates it.
_zen_profile() {
    local ini="$HOME/.config/zen/installs.ini" dir
    [[ -f "$ini" ]] || timeout 20 zen-browser --headless --no-remote about:blank &>/dev/null || true
    dir=$(sed -n 's/^Default=//p' "$ini" 2>/dev/null | head -1)
    [[ -n "$dir" ]] && printf '%s\n' "$HOME/.config/zen/$dir"
}

if command -v zen-browser &>/dev/null && zen_profile=$(_zen_profile) && [[ -d "$zen_profile" ]]; then
    _link "$REPO_DIR/zen/userChrome.css"  "$zen_profile/chrome/userChrome.css"
    _link "$REPO_DIR/zen/userContent.css" "$zen_profile/chrome/userContent.css"
    _link "$REPO_DIR/zen/user.js"         "$zen_profile/user.js"
else
    warn "Zen profile not found: start Zen once, then re-run install.sh"
fi

# ── Script permissions ─────────────────────────────────────────────────────────

for script in "$REPO_DIR"/scripts/*.{sh,py}; do
    [[ -f "$script" ]] && chmod +x "$script"
done
success "Scripts marked executable"

# ── Calendar feeds (secret iCal URLs are credentials, so never symlinked) ──────

if [[ ! -e "$HOME/.config/calendars.yaml" ]]; then
    install -m 600 "$REPO_DIR/scripts/calendars.example.yaml" "$HOME/.config/calendars.yaml"
    success "Wrote $HOME/.config/calendars.yaml (add your secret iCal URLs)"
else
    success "$HOME/.config/calendars.yaml (kept)"
fi

# ── Claude Code hooks (caffeine's "while Claude works" mode) ───────────────────

# Merged into ~/.claude/settings.json: stale claude-busy.sh entries are replaced,
# every other setting and hook is kept.
_install_claude_hooks() {
    local settings="$HOME/.claude/settings.json" merged
    mkdir -p "$(dirname "$settings")"
    [[ -s "$settings" ]] || echo '{}' >"$settings"
    merged=$(mktemp)
    jq '
        def hook($matcher; $event): {
            matcher: $matcher,
            hooks: [{type: "command", command: "~/.config/scripts/claude-busy.sh \($event) 2>/dev/null || true"}]
        };
        def without_busy: map(select(all(.hooks[]?; .command | contains("claude-busy.sh") | not)));
        reduce (
            ["SessionStart", "", "start"],
            ["UserPromptSubmit", "", "busy"],
            ["PostToolUse", "", "busy"],
            ["Stop", "", "stop"],
            ["Notification", "permission_prompt|elicitation_dialog", "idle"],
            ["SessionEnd", "", "end"]
        ) as [$event, $matcher, $arg]
            (.; .hooks[$event] = ((.hooks[$event] // []) | without_busy) + [hook($matcher; $arg)])
    ' "$settings" >"$merged"
    if cmp -s "$settings" "$merged"; then
        rm -f "$merged"
        success "Claude Code busy hooks already installed"
    else
        [[ $(<"$settings") == '{}' ]] || _backup "$settings"
        mv "$merged" "$settings"
        success "Claude Code busy hooks merged into $settings"
    fi
}

_install_claude_hooks

# ── Dark-mode preference (so Zen / GTK / portal apps render dark) ──────────────

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null \
        && success "Dark mode preference set (color-scheme = prefer-dark)"
fi

# ── Font cache (picks up Apple emoji + fontconfig prefs) ───────────────────────

if command -v fc-cache &>/dev/null; then
    fc-cache -f >/dev/null 2>&1 && success "Font cache refreshed"
fi

# ── GTK theme — written directly, not symlinked ────────────────────────────────

_write_gtk_settings() {
    local v="$1"
    local dir="$HOME/.config/gtk-${v}.0"
    mkdir -p "$dir"
    cat >"$dir/settings.ini" <<EOF
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    success "GTK $v settings written"
}

_write_gtk_settings 3
_write_gtk_settings 4

# Adwaita GTK3 hardcodes its selection colour, so Thunar & co. need selectors, not @define-color.
cat >"$HOME/.config/gtk-3.0/gtk.css" <<'EOF'
selection,
*:selected,
.view:selected,
row:selected,
treeview.view:selected,
iconview:selected {
    background-color: #83a598;
    color: #1d2021;
}
EOF
success "GTK 3 sage selection written"

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface font-name 'Inter 11'
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gsettings set org.gnome.desktop.interface cursor-size 24
    # libadwaita only offers named accents; slate is the closest to sage #83a598.
    gsettings set org.gnome.desktop.interface accent-color 'slate'
    success "GTK font, cursor and accent set via gsettings"
fi

# XCursor falls back to the "default" theme when the configured one is missing.
mkdir -p "$HOME/.local/share/icons/default"
cat >"$HOME/.local/share/icons/default/index.theme" <<'EOF'
[Icon Theme]
Inherits=Bibata-Modern-Classic
EOF
success "Cursor fallback set to Bibata-Modern-Classic"

# ── Microcode — the boot entry must load the image matching this CPU ─────────

if [[ -n "$UCODE" ]]; then
    if grep -qs "/$UCODE.img" /boot/loader/entries/*.conf; then
        success "$UCODE loaded by the systemd-boot entries"
    else
        warn "No /boot/loader/entries/*.conf loads /$UCODE.img — add 'initrd /$UCODE.img' before the initramfs line"
    fi
fi

# ── udev rules (8BitDo) ─────────────────────────────────────────────────────────

for rule in "$REPO_DIR"/udev/*.rules; do
    dst="/etc/udev/rules.d/$(basename "$rule")"
    if sudo cmp -s "$rule" "$dst"; then
        success "$(basename "$rule") up to date"
    else
        sudo install -m 644 "$rule" "$dst"
        success "Installed $dst"
    fi
done
sudo udevadm control --reload-rules

# ── Wallpaper ──────────────────────────────────────────────────────────────────

printf "\n%s\n" "${BOLD}Wallpaper setup:${NC}"
info "waypaper manages wallpaper — run 'waypaper' (or Super+Shift+I) to pick one"
info "Config: ~/.config/waypaper/config.ini  (default folder: ~/Pictures/backgrounds)"

# ── Laptop power profiles ─────────────────────────────────────────────────────

if $IS_LAPTOP; then
    sudo systemctl enable --now power-profiles-daemon && success "power-profiles-daemon enabled"
fi

# ── Bluetooth (the bar's Bluetooth dropdown talks to bluez) ───────────────────

if systemctl is-enabled bluetooth &>/dev/null; then
    success "bluetooth enabled"
else
    sudo systemctl enable --now bluetooth && success "bluetooth enabled"
fi

# ── Networking (NetworkManager; keep iwd from fighting over wifi) ──────────────

if systemctl is-enabled NetworkManager &>/dev/null; then
    success "NetworkManager enabled"
else
    sudo systemctl enable --now NetworkManager && success "NetworkManager enabled"
fi
if systemctl is-active iwd &>/dev/null; then
    warn "iwd is active and conflicts with NetworkManager's wpa_supplicant backend — masking it"
    sudo systemctl disable --now iwd 2>/dev/null || true
    sudo systemctl mask iwd 2>/dev/null || true
    success "iwd stopped + masked (NetworkManager now owns wifi)"
fi

# ── greetd (optional — requires sudo + systemd) ────────────────────────────────

printf "\n%s\n" "${BOLD}greetd / ReGreet setup (optional):${NC}"
read -r -p "  Configure greetd as boot greeter? Requires sudo. [y/N] " yn
if [[ "$yn" =~ ^[yY]$ ]]; then
    sudo mkdir -p /etc/greetd

    _backup_sudo /etc/greetd/config.toml
    sudo tee /etc/greetd/config.toml >/dev/null <<'TOML'
[terminal]
vt = 1

[default_session]
command = "cage -s -- regreet --style /etc/greetd/regreet.css"
user = "greeter"
TOML

    # wallpaper.sh renders a blurred copy of the current wallpaper here; the greeter
    # user can only read world-readable paths, so the dir lives outside $HOME.
    sudo install -d -o "$USER" -g "$(id -gn)" -m 755 /usr/local/share/greeter
    "$REPO_DIR/scripts/wallpaper.sh" || true

    _backup_sudo /etc/greetd/regreet.toml
    sudo tee /etc/greetd/regreet.toml >/dev/null <<'TOML'
[background]
path = "/usr/local/share/greeter/background.jpg"
fit = "Cover"

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Bibata-Modern-Classic"
font_name = "Inter 12"
icon_theme_name = "Papirus-Dark"
theme_name = "Adwaita"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]

[appearance]
greeting_msg = "Welcome back"

[widget.clock]
format = "%a %-d %b  %H:%M"
resolution = "1s"
TOML

    # Neutral chrome, same tokens as hyprlock/swaync/Zen; the background image is
    # already blurred and dimmed, so the translucent card reads as frosted glass.
    _backup_sudo /etc/greetd/regreet.css
    sudo tee /etc/greetd/regreet.css >/dev/null <<'CSS'
window {
    background-color: #1c1c1e;
    color: rgba(255, 255, 255, 0.9);
}

frame.background {
    background-color: rgba(30, 30, 33, 0.72);
    color: rgba(255, 255, 255, 0.9);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 18px;
    box-shadow: 0 18px 50px rgba(0, 0, 0, 0.45);
    padding: 12px;
}

label {
    color: rgba(255, 255, 255, 0.9);
}

#message_label {
    font-size: 17px;
    font-weight: 600;
}

#clock_frame {
    background: none;
    border: none;
    box-shadow: none;
}

#clock_frame label {
    font-size: 22px;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.92);
}

entry,
combobox button,
dropdown > button {
    background-color: rgba(255, 255, 255, 0.06);
    color: rgba(255, 255, 255, 0.9);
    caret-color: #83a598;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    min-height: 36px;
    box-shadow: none;
}

entry:focus-within {
    border-color: #83a598;
    box-shadow: 0 0 0 3px rgba(131, 165, 152, 0.28);
    outline: none;
}

/* GTK's built-in theme paints buttons with a background-image gradient, which
   would cover any background-color set here. */
button,
window button.suggested-action,
window button.destructive-action {
    background-image: none;
}

button {
    background-color: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
    border: none;
    border-radius: 10px;
    min-height: 36px;
    box-shadow: none;
}

button:hover {
    background-color: rgba(255, 255, 255, 0.14);
}

window button.suggested-action {
    background-color: #83a598;
    font-weight: 600;
}

window button.suggested-action label {
    color: #1d2021;
}

window button.suggested-action:hover {
    background-color: #93b3a6;
}

window button.destructive-action {
    background-color: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

window button.destructive-action:hover {
    background-color: rgba(255, 105, 97, 0.85);
    color: #1d2021;
}

popover > contents,
popover.background > contents,
menu {
    background-color: rgba(36, 36, 40, 0.96);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 12px;
    box-shadow: 0 12px 30px rgba(0, 0, 0, 0.4);
}

listbox row,
popover modelbutton {
    border-radius: 8px;
}

listbox row:selected,
popover modelbutton:hover {
    background-color: #83a598;
    color: #1d2021;
}

infobar,
infobar > revealer > box {
    background-color: rgba(255, 105, 97, 0.16);
    color: rgba(255, 255, 255, 0.9);
    border-radius: 10px;
}
CSS
    success "Wrote greetd config + regreet.toml + regreet.css"

    for dm in sddm lightdm gdm; do
        if systemctl is-enabled "$dm" &>/dev/null; then
            warn "Detected active DM: $dm — disable it before enabling greetd"
            warn "  sudo systemctl disable $dm"
        fi
    done

    sudo systemctl enable greetd
    success "greetd enabled (active on next boot)"

    # Keep only the plain Hyprland session (drop the uwsm "user management" entry)
    if [[ -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]]; then
        sudo rm -f /usr/share/wayland-sessions/hyprland-uwsm.desktop
        success "Removed hyprland-uwsm.desktop — only plain Hyprland shows in the greeter"
    else
        success "hyprland-uwsm.desktop already removed"
    fi
else
    info "Skipping greetd — start Hyprland manually with: Hyprland"
fi

# ── Reload Hyprland if running ─────────────────────────────────────────────────

printf "\n"
if pgrep -x Hyprland &>/dev/null; then
    read -r -p "  Hyprland is running — reload now? [y/N] " yn
    if [[ "$yn" =~ ^[yY]$ ]]; then
        hyprctl reload
        success "Hyprland reloaded"
    fi
else
    info "Hyprland not running — start with: Hyprland"
fi

# ── Done ───────────────────────────────────────────────────────────────────────

printf "\n%s\n" "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf "  %s\n\n" "${GREEN}Installation complete!${NC}"
printf "  To reload configs at any time:\n"
printf "    %s\n"   "${BOLD}hyprctl reload${NC}"
printf "    %s\n\n" "${BOLD}pkill -x 'qs|quickshell'; setsid -f qs${NC}"
printf "%s\n\n" "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

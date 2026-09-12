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
        waybar swaync
        rofi-wayland wl-clipboard cliphist
        thunar
        firefox
        grim slurp
        bat libnotify
        pipewire wireplumber
        bluez bluez-utils btop
        networkmanager
        polkit-gnome greetd playerctl pavucontrol
        papirus-icon-theme
        qt5-wayland qt6-wayland
        gamemode lib32-gamemode
        ttf-mononoki-nerd
        wf-recorder pacman-contrib jq
    )

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
        hyprpicker
        waypaper
        greetd-regreet
        cage
        bluetui
        obsidian
        catppuccin-cursors
        ttf-apple-emoji
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

# ── Font check ─────────────────────────────────────────────────────────────────

_check_font() {
    fc-list 2>/dev/null | grep -qi "mononoki nerd font" && return 0
    return 1
}

if _check_font; then
    success "Mononoki Nerd Font"
else
    warn "Mononoki Nerd Font not found — installing ttf-mononoki-nerd below"
fi

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
_link "$REPO_DIR/waybar"                       "$HOME/.config/waybar"
_link "$REPO_DIR/rofi"                         "$HOME/.config/rofi"
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

# ── Script permissions ─────────────────────────────────────────────────────────

for script in "$REPO_DIR"/scripts/*; do
    [[ -f "$script" ]] && chmod +x "$script"
done
success "Scripts marked executable"

# ── Dark-mode preference (so Firefox / GTK / portal apps render dark) ──────────

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
gtk-font-name=Mononoki Nerd Font 11
gtk-cursor-theme-name=Catppuccin-Mocha-Dark-Cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    success "GTK $v settings written"
}

_write_gtk_settings 3
_write_gtk_settings 4

# ── Wallpaper ──────────────────────────────────────────────────────────────────

printf "\n%s\n" "${BOLD}Wallpaper setup:${NC}"
info "waypaper manages wallpaper — run 'waypaper' (or Super+Shift+I) to pick one"
info "Config: ~/.config/waypaper/config.ini  (default folder: ~/Pictures/backgrounds)"

# ── greetd (optional — requires sudo + systemd) ────────────────────────────────

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

    _backup_sudo /etc/greetd/regreet.toml
    sudo tee /etc/greetd/regreet.toml >/dev/null <<'TOML'
[background]
path = ""
fit = "Cover"

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Catppuccin-Mocha-Dark-Cursors"
font_name = "Mononoki Nerd Font 11"
icon_theme_name = "Papirus-Dark"
theme_name = "Adwaita"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]
TOML

    # Gruvbox, boxy chip style — matches waybar/hyprlock rather than a
    # third-party GTK theme, since ReGreet loads this CSS directly.
    _backup_sudo /etc/greetd/regreet.css
    sudo tee /etc/greetd/regreet.css >/dev/null <<'CSS'
/* Gruvbox — boxy chip style, matches waybar/hyprlock
   base #282828  surface #3c3836  overlay #504945
   muted #7c6f64  subtle #a89984  text #ebdbb2  love #fb4934  gold #fabd2f
*/

window {
    background-color: #282828;
}

frame.background {
    background-color: rgba(60, 56, 54, 0.85);
    color: #ebdbb2;
    border: 1px solid #504945;
    border-radius: 0px;
    box-shadow: none;
}

label {
    color: #ebdbb2;
}

entry {
    background-color: #282828;
    color: #ebdbb2;
    caret-color: #ebdbb2;
    border: 1px solid #504945;
    border-radius: 0px;
}

entry:focus-within {
    border: 2px solid #8ec07c;
    outline: 1px solid rgba(142, 192, 124, 0.4);
    outline-offset: 2px;
}

/* usernames_box is a GtkComboBoxText; its dropdown popover renders its
   entries as list rows, so style those flat too. */
listbox row {
    background-color: #3c3836;
    border: 1px solid #504945;
    border-radius: 0px;
}

listbox row:selected {
    background-color: #504945;
    color: #ebdbb2;
    border-left: 3px solid #8ec07c;
}

/* Session/user combobox popovers otherwise fall back to a rounded default
   GTK popup, breaking the flat look mid-flow. */
popover,
popover.background,
menu {
    background-color: #282828;
    border: 1px solid #504945;
    border-radius: 0px;
}

menu menuitem:hover,
popover row:hover {
    background-color: #504945;
}

combobox box,
combobox button {
    background-color: #282828;
    color: #ebdbb2;
    border-radius: 0px;
}

button {
    background-color: #504945;
    color: #ebdbb2;
    border: none;
    border-radius: 0px;
}

button:hover {
    background-color: #7c6f64;
}

button.suggested-action {
    background-color: #ebdbb2;
    color: #282828;
    border: 1px solid #8ec07c;
}

button.suggested-action:hover {
    background-color: #fabd2f;
}

button.destructive-action {
    background-color: #fb4934;
    color: #282828;
}

infobar {
    background-color: #3c3836;
    color: #ebdbb2;
    border-radius: 0px;
}

/* #message_label is ReGreet's top status/greeting label; #clock_frame wraps
   its clock widget. Sized up so they don't look disconnected from
   hyprlock's larger clock text. */
#message_label {
    font-size: 18px;
}

#clock_frame label {
    font-size: 32px;
}

/* TODO: confirm ReGreet's actual capslock CSS class/selector name — as of
   the current upstream source (rharish101/ReGreet), there is no capslock
   indicator widget at all, so this selector is a guess for if/when one is
   added, following the same naming convention as other GTK greeters. */
.capslock-warning {
    color: #fabd2f;
    font-weight: bold;
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
printf "    %s\n\n" "${BOLD}killall waybar && waybar &${NC}"
printf "%s\n" "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

printf "\n%s  (all should be visible)\n" "${BOLD}Character check:${NC}"
printf "  UI          ▶  ◀  ▸  …  ●\n"
printf "  Box         ─  │  ╭  ╮  ╯  ╰\n"
printf "  Powerline   \ue0b0  \ue0b1  \ue0b2  \ue0b3   %s\n\n" "${DIM}(blank = Nerd Font missing)${NC}"

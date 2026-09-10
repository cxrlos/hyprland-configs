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
        ttf-monaspace-nerd
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
    # Nerd-patched family is "Monaspice…"; non-patched is "Monaspace". Match both.
    fc-list 2>/dev/null | grep -qi "monasp" && return 0
    return 1
}

if _check_font; then
    success "Monaspace Nerd Font (Neon)"
else
    warn "Monaspace Nerd Font not found — installing ttf-monaspace-nerd from AUR below"
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
gtk-font-name=MonaspiceNe Nerd Font 11
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

    sudo tee /etc/greetd/config.toml >/dev/null <<'TOML'
[terminal]
vt = 1

[default_session]
command = "cage -s -- regreet"
user = "greeter"
TOML

    sudo tee /etc/greetd/regreet.toml >/dev/null <<'TOML'
[background]
path = ""
fit = "Cover"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]
TOML
    success "Wrote greetd config + regreet.toml"

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

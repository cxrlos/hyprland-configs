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
    info "Syncing package database..."
    sudo pacman -Sy --noconfirm

    local pacman_deps=(
        hyprland hyprlock hypridle swww
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        waybar swaync
        rofi-wayland wl-clipboard cliphist
        yazi
        grim slurp
        bat libnotify
        pipewire wireplumber
        bluez bluez-utils btop
        polkit-gnome greetd brightnessctl playerctl pavucontrol
        papirus-icon-theme
        qt5-wayland qt6-wayland
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
        tuigreet
        bluetui
        rose-pine-gtk-theme
        nwg-look
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
    ls "$HOME/.local/share/fonts"/BerkeleyMono* &>/dev/null && return 0
    fc-list 2>/dev/null | grep -qi "BerkeleyMono\|Berkeley Mono" && return 0
    return 1
}

if _check_font; then
    success "BerkeleyMono Nerd Font"
else
    warn "BerkeleyMono Nerd Font not found"
    warn "  Berkeley Mono is commercial — https://berkeleygraphics.com/typefaces/berkeley-mono/"
    warn "  Install the Nerd Font patched variant then re-run."
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
_link "$REPO_DIR/scripts"                      "$HOME/.config/scripts"

# screenshot exposed in PATH
mkdir -p "$HOME/.local/bin"
_link "$REPO_DIR/scripts/screenshot.sh"        "$HOME/.local/bin/screenshot"

# ── Script permissions ─────────────────────────────────────────────────────────

for script in "$REPO_DIR"/scripts/*.sh; do
    [[ -f "$script" ]] && chmod +x "$script"
done
success "Scripts marked executable"

# ── GTK theme — written directly, not symlinked ────────────────────────────────

_write_gtk_settings() {
    local v="$1" dir="$HOME/.config/gtk-${v}.0"
    mkdir -p "$dir"
    cat >"$dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=rose-pine
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=BerkeleyMono Nerd Font Mono 12
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
info "Config: ~/.config/waypaper/config.ini  (default folder: ~/Pictures)"

# ── greetd (optional — requires sudo + systemd) ────────────────────────────────

printf "\n%s\n" "${BOLD}greetd / tuigreet setup (optional):${NC}"
read -r -p "  Configure greetd as boot greeter? Requires sudo. [y/N] " yn
if [[ "$yn" =~ ^[yY]$ ]]; then
    sudo mkdir -p /etc/greetd
    sudo tee /etc/greetd/config.toml >/dev/null <<'TOML'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland --time --remember --asterisks --greeting 'Welcome back.' --width 60"
user = "greeter"
TOML
    success "Wrote /etc/greetd/config.toml"

    for dm in sddm lightdm gdm; do
        if systemctl is-enabled "$dm" &>/dev/null; then
            warn "Detected active DM: $dm — disable it before enabling greetd"
            warn "  sudo systemctl disable $dm"
        fi
    done

    sudo systemctl enable greetd
    success "greetd enabled (active on next boot)"
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

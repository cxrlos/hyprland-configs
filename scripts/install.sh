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
        grim slurp
        bat libnotify
        pipewire wireplumber
        bluez bluez-utils btop
        networkmanager
        polkit-gnome greetd playerctl pavucontrol
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
        greetd-regreet
        cage
        bluetui
        zen-browser-bin
        obsidian
        catppuccin-gtk-theme-mocha
        catppuccin-cursors
        ttf-monaspace-nerd
        ttf-apple-emoji
        nwg-displays
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

# screenshot + steam (resolution fix) exposed in PATH
mkdir -p "$HOME/.local/bin"
_link "$REPO_DIR/scripts/screenshot.sh"        "$HOME/.local/bin/screenshot"
_link "$REPO_DIR/scripts/steam.sh"             "$HOME/.local/bin/steam"

# ── Zen Browser (declarative prefs + chrome CSS) ───────────────────────────────
#
# Only the declarative layer is tracked: user.js (prefs, re-applied every launch)
# and chrome/userChrome.css (UI font). The Catppuccin Mod, accent, extensions and
# data stay in Zen's per-account sync. Profile paths are randomly hashed (and may
# contain a space), so resolve the launched profile from profiles.ini.

_zen_default_profile() {
    local ini="$HOME/.config/zen/profiles.ini" rel
    [[ -f "$ini" ]] || return 1
    # The [Install*] section's Default= is the profile Zen actually launches.
    rel=$(awk -F= '/^\[Install/{f=1} f&&/^Default=/{print $2; exit}' "$ini")
    # Fallback: the [Profile*] flagged Default=1.
    if [[ -z "$rel" ]]; then
        rel=$(awk -F= '/^\[Profile/{path=""} /^Path=/{path=$2} /^Default=1/{print path; exit}' "$ini")
    fi
    [[ -n "$rel" ]] || return 1
    printf "%s\n" "$HOME/.config/zen/$rel"
}

_link_zen() {
    local profile
    if ! profile=$(_zen_default_profile); then
        skip "Zen profile (launch Zen once, then re-run install)"
        return 0
    fi
    _link "$REPO_DIR/zen/user.js"               "$profile/user.js"
    mkdir -p "$profile/chrome"                  # keep the Mod's zen-themes.css intact
    _link "$REPO_DIR/zen/chrome/userChrome.css" "$profile/chrome/userChrome.css"
}
_link_zen

# ── Script permissions ─────────────────────────────────────────────────────────

for script in "$REPO_DIR"/scripts/*; do
    [[ -f "$script" ]] && chmod +x "$script"
done
success "Scripts marked executable"

# ── Dark-mode preference (so Zen / GTK / portal apps render dark) ───────────────

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
gtk-theme-name=catppuccin-mocha-sky-standard+default
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

# ── Verify the Catppuccin GTK theme name (varies by package version) ────────────

_verify_gtk_theme() {
    local theme="catppuccin-mocha-sky-standard+default"
    if [[ -d "$HOME/.local/share/themes/$theme" || -d "/usr/share/themes/$theme" ]]; then
        success "GTK theme present: $theme"
        return 0
    fi
    warn "GTK theme '$theme' not found — the package may name it differently"
    local found
    found=$(ls -d "$HOME/.local/share/themes/"*[Cc]atppuccin* /usr/share/themes/*[Cc]atppuccin* 2>/dev/null || true)
    if [[ -n "$found" ]]; then
        warn "  Installed Catppuccin themes:"
        printf '    %s\n' $found
    else
        warn "  No Catppuccin GTK theme installed (expected catppuccin-gtk-theme-mocha)"
    fi
    warn "  Set the right name in: hypr/hyprland.conf (GTK_THEME), scripts/thunar-launch.sh, ~/.config/gtk-{3,4}.0/settings.ini"
}
_verify_gtk_theme

# ── Thunar GTK CSS overrides (Catppuccin) ──────────────────────────────────────

_merge_thunar_css() {
    local gtk_css="$HOME/.config/gtk-3.0/gtk.css"
    local thunar_css="$REPO_DIR/thunar/gtk.css"
    if [[ -f "$thunar_css" ]]; then
        if [[ -f "$gtk_css" ]] && grep -q "Thunar — Catppuccin" "$gtk_css" 2>/dev/null; then
            skip "Thunar CSS already in gtk.css"
        else
            mkdir -p "$(dirname "$gtk_css")"
            [[ -f "$gtk_css" ]] || touch "$gtk_css"
            printf "\n/* Appended by hyprland-configs install.sh — Thunar Catppuccin */\n" >>"$gtk_css"
            cat "$thunar_css" >>"$gtk_css"
            success "Appended Thunar Catppuccin CSS to gtk-3.0/gtk.css"
        fi
    fi
}
_merge_thunar_css

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

    # Greeter background — a dedicated repo asset. The greeter runs as the
    # unprivileged 'greeter' user (can't read your home) and is intentionally
    # independent of the waypaper desktop wallpaper, which you manage separately.
    greeter_bg="/usr/share/backgrounds/greeter-bg.jpg"
    if [[ -f "$REPO_DIR/assets/greeter-bg.jpg" ]]; then
        sudo mkdir -p /usr/share/backgrounds
        sudo cp "$REPO_DIR/assets/greeter-bg.jpg" "$greeter_bg"
    fi

    sudo tee /etc/greetd/config.toml >/dev/null <<'TOML'
[terminal]
vt = 1

[default_session]
command = "cage -s -- regreet"
user = "greeter"
TOML

    sudo tee /etc/greetd/regreet.toml >/dev/null <<TOML
[background]
path = "$greeter_bg"
fit = "Cover"

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Catppuccin-Mocha-Dark-Cursors"
font_name = "MonaspiceNe Nerd Font 11"
icon_theme_name = "Papirus-Dark"
theme_name = "catppuccin-mocha-sky-standard+default"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]
TOML
    success "Wrote greetd config + regreet.toml (ReGreet · Catppuccin sky)"

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

printf "\n%s\n" "${BOLD}Next step:${NC}"
info "Sign into Zen to sync account data (extensions, bookmarks, passwords)"
info "Zen prefs (user.js) + chrome CSS are symlinked from the repo — restart Zen to apply"
info "Theme: install the Catppuccin Mocha Zen Mod; accent is pinned to sky by user.js"

printf "\n%s  (all should be visible)\n" "${BOLD}Character check:${NC}"
printf "  UI          ▶  ◀  ▸  …  ●\n"
printf "  Box         ─  │  ╭  ╮  ╯  ╰\n"
printf "  Powerline   \ue0b0  \ue0b1  \ue0b2  \ue0b3   %s\n\n" "${DIM}(blank = Nerd Font missing)${NC}"

#!/usr/bin/env bash
# ============================================================================
# Akari Hoshizaki Hyprland Theme Installer & Symlink Manager
# Safely backs up existing configs, unlinks HakuSpace, and deploys akari-theme.
# ============================================================================
set -euo pipefail

THEME_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +'%Y%m%d-%H%M%S')"
BACKUP_DIR="$HOME/.backup/pre-akari-theme-${STAMP}"

echo "[1/5] Backing up existing configs to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR/.config" "$BACKUP_DIR/.local/share/fcitx5"

for cfg in hypr quickshell wofi kitty cava btop fastfetch fcitx5 waybar rofi swaync mako; do
    if [[ -e "$HOME/.config/$cfg" || -L "$HOME/.config/$cfg" ]]; then
        cp -a "$HOME/.config/$cfg" "$BACKUP_DIR/.config/" 2>/dev/null || true
    fi
done
if [[ -d "$HOME/.local/share/fcitx5/themes" ]]; then
    cp -a "$HOME/.local/share/fcitx5/themes" "$BACKUP_DIR/.local/share/fcitx5/" 2>/dev/null || true
fi

echo "[2/5] Unlinking HakuSpace managed symlinks ..."
if [[ -x "$HOME/hakuspace/unlink.sh" ]]; then
    "$HOME/hakuspace/unlink.sh" --all || true
    "$HOME/hakuspace/unlink.sh" hyprland || true
fi

echo "[3/5] Deploying Akari Theme configurations & scripts ..."
mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.config/fontconfig" \
    "$HOME/.config/hypr" \
    "$HOME/.config/quickshell" \
    "$HOME/.config/wofi" \
    "$HOME/.config/kitty" \
    "$HOME/.config/cava" \
    "$HOME/.config/btop/themes" \
    "$HOME/.config/fastfetch" \
    "$HOME/.config/fcitx5/conf" \
    "$HOME/.local/share/fcitx5/themes" \
    "$HOME/.local/state/akari-theme"

# Link helper scripts
for script in "$THEME_DIR"/bin/*; do
    chmod +x "$script"
    ln -sfn "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Clean old hypr symlink leftovers and link new modular Hyprland 0.57+ config
rm -rf "$HOME/.config/hypr/config" "$HOME/.config/hypr/hyprlock_tiny.conf"
ln -sfn "$THEME_DIR/config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
ln -sfn "$THEME_DIR/config/hypr/modules"      "$HOME/.config/hypr/modules"
ln -sfn "$THEME_DIR/config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
ln -sfn "$THEME_DIR/config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
if [[ ! -f "$HOME/.config/hypr/user.lua" ]]; then
    cp "$THEME_DIR/config/hypr/user.lua" "$HOME/.config/hypr/user.lua"
fi

# Link Quickshell Akari shell
ln -sfn "$THEME_DIR/config/quickshell/akari" "$HOME/.config/quickshell/akari"

# Link Wofi
ln -sfn "$THEME_DIR/config/wofi/config"    "$HOME/.config/wofi/config"
ln -sfn "$THEME_DIR/config/wofi/style.css" "$HOME/.config/wofi/style.css"

# Link Kitty, Cava, Btop, Fastfetch
ln -sfn "$THEME_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
ln -sfn "$THEME_DIR/config/kitty/tab_bar.py" "$HOME/.config/kitty/tab_bar.py"
ln -sfn "$THEME_DIR/config/cava/config"      "$HOME/.config/cava/config"
ln -sfn "$THEME_DIR/config/btop/btop.conf"   "$HOME/.config/btop/btop.conf"
ln -sfn "$THEME_DIR/config/btop/themes/akari-star.theme" "$HOME/.config/btop/themes/akari-star.theme"
ln -sfn "$THEME_DIR/config/fastfetch/config.jsonc"   "$HOME/.config/fastfetch/config.jsonc"
ln -sfn "$THEME_DIR/config/fastfetch/akari-star.txt" "$HOME/.config/fastfetch/akari-star.txt"

# Link Fontconfig (JetBrainsMono Nerd Font first, CJK fallback)
ln -sfn "$THEME_DIR/config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
fc-cache -f >/dev/null 2>&1 || true

# Link Fcitx5 candidate window theme
ln -sfn "$THEME_DIR/local-share/fcitx5/themes/akari-star" "$HOME/.local/share/fcitx5/themes/akari-star"
cp "$THEME_DIR/config/fcitx5/conf/classicui.conf" "$HOME/.config/fcitx5/conf/classicui.conf"

# Preserve current active wallpaper
if [[ ! -f "$HOME/.local/state/akari-theme/wallpaper" ]]; then
    printf '%s\n' "$HOME/.local/share/wallpapers/akari.jpg" > "$HOME/.local/state/akari-theme/wallpaper"
fi

# Apply dark color-scheme preference for GTK apps
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

echo "[4/5] Reloading live desktop daemons ..."
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || hyprctl version >/dev/null 2>&1; then
    # Stop old HakuSpace background processes cleanly
    pkill -f "qs_supervisor" 2>/dev/null || true
    pkill -f "(qs|quickshell).*(hakuspace|-c hakuspace)" 2>/dev/null || true
    pkill -x waybar 2>/dev/null || true
    pkill -x swaync 2>/dev/null || true
    pkill -x mako 2>/dev/null || true
    pkill -f "edge_trigger" 2>/dev/null || true
    pkill -f "desktop_icons.py" 2>/dev/null || true
    pkill -f "cava_layer.py" 2>/dev/null || true

    hyprctl reload || true
    "$HOME/.local/bin/akari-wallpaper" --restore || true
    hyprctl dispatch "hl.dsp.exec_cmd('fcitx5 -d --replace')" >/dev/null 2>&1 || true
    "$HOME/.local/bin/akari-ctl" shell-start || true
fi

echo "[5/5] Done! Backup saved at: $BACKUP_DIR"

#!/usr/bin/env bash
set -euo pipefail

BAR_SRC="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BAR_DIR="$CONFIG/quickshell/bar"

echo "==> quickshell bar installer"
echo "    Source: $BAR_SRC"
echo "    Target: $BAR_DIR"

# ── 1. Install dependencies ──
if command -v pacman &>/dev/null; then
    echo ""
    echo "==> Installing packages (pacman)..."
    sudo pacman -S --needed --noconfirm quickshell ttf-material-symbols-variable
elif command -v apt &>/dev/null; then
    echo ""
    echo "==> Installing packages (apt)..."
    sudo apt install -y quickshell fonts-material-symbols
else
    echo "!!> Unknown package manager. Install quickshell and Material Symbols font manually."
fi

# ── 2. Create directories ──
mkdir -p "$BAR_DIR/modules" "$BAR_DIR/panels" "$BAR_DIR/shaders" "$BAR_DIR/assets"

# ── 3. Copy files ──
echo ""
echo "==> Copying bar files..."
cp -v "$BAR_SRC/shell.qml"            "$BAR_DIR/shell.qml"
cp -v "$BAR_SRC/BarSlot.qml"          "$BAR_DIR/BarSlot.qml"
cp -v "$BAR_SRC/Bar.qml"              "$BAR_DIR/Bar.qml"
cp -v "$BAR_SRC/Theme.qml"            "$BAR_DIR/Theme.qml"
cp -v "$BAR_SRC/Palette.js"           "$BAR_DIR/Palette.js"
cp -v "$BAR_SRC/IconMap.js"           "$BAR_DIR/IconMap.js"
cp -v "$BAR_SRC/assets/bob2.png"      "$BAR_DIR/assets/bob2.png"
cp -v "$BAR_SRC/shaders/"*.qsb        "$BAR_DIR/shaders/"

for f in "$BAR_SRC/modules/"*.qml; do
    cp -v "$f" "$BAR_DIR/modules/"
done

for f in "$BAR_SRC/panels/"*.qml "$BAR_SRC/panels/"*.js; do
    cp -v "$f" "$BAR_DIR/panels/"
done

# ── 4. Install omaniri theme hook ──
HOOK_DIR="$CONFIG/omaniri/hooks/theme-set.d"
mkdir -p "$HOOK_DIR"
cat > "$HOOK_DIR/50-quickshell-bar.sh" << 'HOOK'
#!/usr/bin/env bash
qs -c bar ipc call theme reload 2>/dev/null || true
HOOK
chmod +x "$HOOK_DIR/50-quickshell-bar.sh"
echo "    -> Installed theme hook: $HOOK_DIR/50-quickshell-bar.sh"

# ── 5. Update niri autostart (replace waybar with quickshell) ──
AUTOSTART="$CONFIG/niri/autostart.kdl"
if [ -f "$AUTOSTART" ]; then
    echo ""
    echo "==> Updating niri autostart..."
    if grep -q "waybar" "$AUTOSTART" 2>/dev/null; then
        sed -i '/waybar/d' "$AUTOSTART"
        echo "    -> Removed waybar from autostart"
    fi
    if ! grep -q "quickshell.*bar" "$AUTOSTART" 2>/dev/null; then
        cat >> "$AUTOSTART" << 'EOF'

# quickshell bar (replaces waybar)
spawn-sh-at-startup "nohup quickshell -p $HOME/.config/quickshell/bar >/dev/null 2>&1 &"
EOF
        echo "    -> Added quickshell bar to autostart"
    else
        echo "    -> quickshell bar already in autostart"
    fi
else
    echo "!!> No niri autostart found at $AUTOSTART"
    echo "    Add this line manually:"
    echo '    spawn-sh-at-startup "nohup quickshell -p $HOME/.config/quickshell/bar >/dev/null 2>&1 &"'
fi

# ── 6. Start the bar ──
echo ""
echo "==> Starting bar..."
kill $(pgrep -f "quickshell.*bar") 2>/dev/null || true
sleep 0.5
nohup quickshell -p "$BAR_DIR" &>/tmp/qs_final.log &
echo "    Started PID: $!"

echo ""
echo "==> Done! Bar is running."

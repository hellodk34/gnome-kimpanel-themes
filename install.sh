#!/bin/bash
set -euo pipefail

EXT_DIR="${KIMPANEL_EXT_DIR:-$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org}"
SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
THEMES_DIR="$SRC_DIR/themes"
DEFAULT_THEME="candlelight-spring"
THEME="${1:-$DEFAULT_THEME}"

list_themes() {
    echo "可用主题："
    for f in "$THEMES_DIR"/*.css; do
        name="$(basename "$f" .css)"
        title="$(head -n 1 "$f" | sed 's|^/\* ||; s| —.*$||')"
        if [ "$name" = "$DEFAULT_THEME" ]; then
            printf '  %-20s %s（默认）\n' "$name" "$title"
        else
            printf '  %-20s %s\n' "$name" "$title"
        fi
    done
    echo
    echo "用法：./install.sh <主题名>    例如：./install.sh midnight-teal"
}

case "$THEME" in
    -h|--help|help)
        list_themes
        exit 0
        ;;
    list|ls)
        list_themes
        exit 0
        ;;
esac

# 允许只写主题名，也允许误带 .css 后缀
THEME="${THEME%.css}"
THEME_FILE="$THEMES_DIR/$THEME.css"

if [ ! -f "$THEME_FILE" ]; then
    echo "错误：找不到主题 '$THEME'。"
    echo
    list_themes
    exit 1
fi

if [ ! -d "$EXT_DIR" ]; then
    echo "错误：找不到扩展目录 $EXT_DIR"
    echo "请先安装 kimpanel 扩展："
    echo "  https://github.com/wengxt/gnome-shell-extension-kimpanel"
    exit 1
fi

echo "==> 应用主题：$THEME"
# 先停用扩展，确保 GNOME Shell 重新读取样式表
if command -v gnome-extensions >/dev/null 2>&1 &&
   gnome-extensions list 2>/dev/null | grep -qx 'kimpanel@kde.org'; then
    gnome-extensions disable kimpanel@kde.org >/dev/null 2>&1 || true
fi

cp "$THEME_FILE" "$EXT_DIR/stylesheet.css"

echo "==> 注册 GSettings schema（用于调整字体）..."
mkdir -p "$SCHEMA_DIR"
cp "$SRC_DIR/org.gnome.shell.extensions.kimpanel.gschema.xml" "$SCHEMA_DIR/"
glib-compile-schemas "$SCHEMA_DIR"

# 重新启用扩展以加载新样式
if command -v gnome-extensions >/dev/null 2>&1 &&
   gnome-extensions list 2>/dev/null | grep -qx 'kimpanel@kde.org'; then
    gnome-extensions enable kimpanel@kde.org >/dev/null 2>&1 || true
fi

echo "==> 完成！当前主题：$THEME"
echo "    如果候选框样式没有变化，请注销后重新登录（Wayland 下最可靠）。"
echo "    切换其他主题：./install.sh list"

#!/usr/bin/env bash
# NOT part of the installable Plasma Groovbx package (color-schemes/, plasma/,
# wallpaper/, icons/). Nothing here runs automatically for anyone who installs
# the theme from KDE Store or otherwise - this is a personal, local workaround
# script, kept in-repo only for convenience.
#
# Root cause (confirmed independent of this theme and of any prior ~/.config
# state, via a clean ~/.config/gtk-3.0 test): kde-gtk-config's
# window-decorations-gtk-module asks KWin to paint the current window
# decoration's close/maximize/minimize buttons offscreen and export each
# state to an SVG under ~/.config/gtk-3.0/assets/ (and gtk-4.0). On this
# machine (Fedora 44, kde-gtk-config 6.7.5, Plasma 6 Wayland) that export
# comes back empty on every regeneration - reproduces with 100% stock
# "Breeze Dark", no custom color scheme or theme involved. It's a
# system-component bug, not something a theme package can fix or ship a
# persistent fix for. Matches a known class of Plasma 6 + Wayland GTK CSD
# button reports; worth filing against kde-gtk-config upstream if not
# already tracked.
#
# This script re-populates the empty SVGs from the real Breeze GTK theme
# assets. Re-run it after switching color scheme / reapplying any Plasma
# theme, since kde-gtk-config regenerates (and re-breaks) them each time.
#
# The stock Breeze assets draw the glyphs in white (#ffffff), meant to sit
# on a dark titlebar. On Plasma Groovbx Light that titlebar is light, so
# white glyphs render invisible. Rather than guess from the active color
# scheme's name (unreliable with Plasma 6's automatic light/dark switching
# - kdeglobals may have no static ColorScheme= key at all), read the
# titlebar's own actual resolved foreground color from [WM] and use that -
# correct for either variant, and for any color scheme, automatically.
set -e
SRC=/usr/share/themes/Breeze/assets

GLYPH_COLOR="#ffffff"
wm_fg="$(grep -A20 '^\[WM\]' "$HOME/.config/kdeglobals" 2>/dev/null | grep '^activeForeground=' | head -1 | cut -d= -f2)"
if [[ "$wm_fg" =~ ^[0-9]+,[0-9]+,[0-9]+$ ]]; then
  GLYPH_COLOR="$(printf '#%02x%02x%02x' ${wm_fg//,/ })"
fi

populate() {
  local dir="$1"
  mkdir -p "$dir"
  cp "$SRC/breeze-close-symbolic.svg" "$dir/close-normal.svg"
  cp "$SRC/breeze-close-active-symbolic.svg" "$dir/close-active.svg"
  sed 's/#ff0404/#fb4934/; s/opacity="0.5"/opacity="1"/' "$SRC/breeze-close-hover-symbolic.svg" > "$dir/close-hover.svg"

  cp "$SRC/breeze-maximize-symbolic.svg" "$dir/maximize-normal.svg"
  cp "$SRC/breeze-maximize-active-symbolic.svg" "$dir/maximize-active.svg"
  cp "$SRC/breeze-maximize-hover-symbolic.svg" "$dir/maximize-hover.svg"

  cp "$SRC/breeze-minimize-symbolic.svg" "$dir/minimize-normal.svg"
  cp "$SRC/breeze-minimize-active-symbolic.svg" "$dir/minimize-active.svg"
  cp "$SRC/breeze-minimize-hover-symbolic.svg" "$dir/minimize-hover.svg"

  cp "$SRC/breeze-maximized-symbolic.svg" "$dir/maximized-normal.svg"
  cp "$SRC/breeze-maximized-active-symbolic.svg" "$dir/maximized-active.svg"
  cp "$SRC/breeze-maximized-hover-symbolic.svg" "$dir/maximized-hover.svg"

  cp "$SRC/breeze-close-symbolic.svg" "$dir/close-backdrop-normal.svg"
  cp "$SRC/breeze-close-active-symbolic.svg" "$dir/close-backdrop-active.svg"
  sed 's/#ff0404/#fb4934/; s/opacity="0.5"/opacity="1"/' "$SRC/breeze-close-hover-symbolic.svg" > "$dir/close-backdrop-hover.svg"
  cp "$SRC/breeze-maximize-symbolic.svg" "$dir/maximize-backdrop-normal.svg"
  cp "$SRC/breeze-maximize-active-symbolic.svg" "$dir/maximize-backdrop-active.svg"
  cp "$SRC/breeze-maximize-hover-symbolic.svg" "$dir/maximize-backdrop-hover.svg"
  cp "$SRC/breeze-minimize-symbolic.svg" "$dir/minimize-backdrop-normal.svg"
  cp "$SRC/breeze-minimize-active-symbolic.svg" "$dir/minimize-backdrop-active.svg"
  cp "$SRC/breeze-minimize-hover-symbolic.svg" "$dir/minimize-backdrop-hover.svg"
  cp "$SRC/breeze-maximized-symbolic.svg" "$dir/maximized-backdrop-normal.svg"
  cp "$SRC/breeze-maximized-active-symbolic.svg" "$dir/maximized-backdrop-active.svg"
  cp "$SRC/breeze-maximized-hover-symbolic.svg" "$dir/maximized-backdrop-hover.svg"

  if [ "$GLYPH_COLOR" != "#ffffff" ]; then
    # Every glyph except close's hover states (those are intentionally red).
    # breeze-minimize-symbolic.svg alone uses #fefefe, not #ffffff - match both.
    sed -i "s/#ffffff/$GLYPH_COLOR/g; s/#fefefe/$GLYPH_COLOR/g" "$dir"/{close,maximize,minimize,maximized}-{normal,active}.svg \
      "$dir"/{close,maximize,minimize,maximized}-backdrop-{normal,active}.svg \
      "$dir"/{maximize,minimize,maximized}-hover.svg \
      "$dir"/{maximize,minimize,maximized}-backdrop-hover.svg
  fi
}

populate "$HOME/.config/gtk-3.0/assets"
[ -d "$HOME/.config/gtk-4.0/assets" ] && populate "$HOME/.config/gtk-4.0/assets"
echo "GTK window button icons restored (glyph color: $GLYPH_COLOR)."

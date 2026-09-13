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
set -e
SRC=/usr/share/themes/Breeze/assets

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
}

populate "$HOME/.config/gtk-3.0/assets"
[ -d "$HOME/.config/gtk-4.0/assets" ] && populate "$HOME/.config/gtk-4.0/assets"
echo "GTK window button icons restored."

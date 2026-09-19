#!/usr/bin/env bash
# NOT part of the installable Plasma Groovbx package - a personal, local
# workaround script, kept in-repo only for convenience.
#
# On at least one machine, kde-gtk-config never finished syncing GTK for
# the session: ~/.config/gtk-3.0/settings.ini was missing
# window-decorations-gtk-module from gtk-modules= (the module responsible
# for exporting KWin's decoration buttons to GTK apps) and had no
# gtk-theme-name= at all, leaving GTK to fall back to its own compiled-in
# default theme instead of Breeze. Symptom: most GTK theming looks right
# (colorreload-gtk-module still runs), but individual CSD buttons render
# in the wrong/unreadable color in some apps (seen with Remmina's
# maximize/restore button) since they never got Breeze's own titlebutton
# styling. A working machine's settings.ini had both set correctly.
#
# This only patches what's missing/empty - it won't overwrite a
# gtk-theme-name you've deliberately set to something else. Log out and
# back in afterward: restarting kded6 alone isn't enough to re-init its
# handshake with already-running apps.
set -e

theme_variant() {
  local bg
  bg="$(grep -A20 '^\[WM\]' "$HOME/.config/kdeglobals" 2>/dev/null | grep '^activeBackground=' | head -1 | cut -d= -f2)"
  if [[ "$bg" =~ ^([0-9]+),([0-9]+),([0-9]+)$ ]]; then
    local r=${BASH_REMATCH[1]} g=${BASH_REMATCH[2]} b=${BASH_REMATCH[3]}
    # Perceptual luminance; below half brightness counts as a dark titlebar.
    if (( (r*299 + g*587 + b*114) / 1000 < 128 )); then
      echo "Breeze-Dark"
      return
    fi
  fi
  echo "Breeze"
}

THEME_NAME="$(theme_variant)"

patch() {
  local ini="$1"
  [ -f "$ini" ] || return
  if grep -q '^gtk-modules=' "$ini"; then
    grep -q '^gtk-modules=.*window-decorations-gtk-module' "$ini" ||
      sed -i '/^gtk-modules=/ s/$/:window-decorations-gtk-module/' "$ini"
  else
    printf 'gtk-modules=colorreload-gtk-module:window-decorations-gtk-module\n' >> "$ini"
  fi
  if grep -q '^gtk-theme-name=' "$ini"; then
    : # already set - respect whatever the user/kde-gtk-config has there
  else
    printf 'gtk-theme-name=%s\n' "$THEME_NAME" >> "$ini"
  fi
  echo "Patched $ini"
}

patch "$HOME/.config/gtk-3.0/settings.ini"
patch "$HOME/.config/gtk-4.0/settings.ini"
echo "Done. Log out and back in for kde-gtk-config to fully re-sync."

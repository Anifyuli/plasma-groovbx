#!/usr/bin/env bash
# Plasma Groovbx installer/uninstaller

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}"

GREEN="$(tput setaf 2 2>/dev/null || true)"
YELLOW="$(tput setaf 3 2>/dev/null || true)"
RED="$(tput setaf 1 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

log()  { printf '%s::%s %s\n' "$GREEN" "$RESET" "$1"; }
warn() { printf '%s::%s %s\n' "$YELLOW" "$RESET" "$1"; }
err()  { printf '%s::%s %s\n' "$RED" "$RESET" "$1" >&2; }

usage() {
  cat <<USAGE
Plasma Groovbx installer

Usage: $(basename "$0") [options]

  -d, --dest DIR   Install destination base (default: $DEST)
  -r, --remove     Uninstall instead of install
  -g, --gtk        Also apply the optional GTK window-button-icon workaround
                   and close-hover snippet, to ~/.config/gtk-3.0 and gtk-4.0
  -h, --help       Show this help
USAGE
}

ACTION=install
WITH_GTK=false

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dest) DEST="$2"; shift 2 ;;
    -r|--remove) ACTION=remove; shift ;;
    -g|--gtk) WITH_GTK=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# source-dir:dest-subdir pairs — each source dir's *children* get installed
# under $DEST/dest-subdir/, or removed from there.
COMPONENTS=(
  "color-schemes:color-schemes"
  "plasma/desktoptheme:plasma/desktoptheme"
  "plasma/look-and-feel:plasma/look-and-feel"
  "icons:icons"
  "wallpaper:wallpapers"
  "yakuake/skins:yakuake/skins"
)

do_install() {
  for pair in "${COMPONENTS[@]}"; do
    src="${pair%%:*}"
    dst="${pair##*:}"
    mkdir -p "$DEST/$dst"
    for item in "$REPO_DIR/$src"/*; do
      name="$(basename "$item")"
      log "Installing $dst/$name"
      cp -r "$item" "$DEST/$dst/"
    done
  done
  log "Done. Apply from System Settings > Appearance > Global Themes > Plasma Groovbx Dark/Light."

  if [ "$WITH_GTK" = true ]; then
    log "Applying optional GTK extras..."
    bash "$REPO_DIR/gtk/fix-window-buttons.sh" || warn "GTK window-button workaround failed, see gtk/fix-window-buttons.sh"
    for v in gtk-3.0 gtk-4.0; do
      mkdir -p "$HOME/.config/$v/assets"
      cp "$REPO_DIR/gtk/assets/gruvbox-close-hover-symbolic.svg" "$HOME/.config/$v/assets/"
      if ! grep -q "Plasma Groovbx" "$HOME/.config/$v/gtk.css" 2>/dev/null; then
        cat "$REPO_DIR/gtk/gtk.css.append" >> "$HOME/.config/$v/gtk.css"
      fi
    done
    warn "kde-gtk-config regenerates its own files on color scheme changes and may undo this; re-run with -g if it does."
  fi
}

do_remove() {
  for pair in "${COMPONENTS[@]}"; do
    src="${pair%%:*}"
    dst="${pair##*:}"
    for item in "$REPO_DIR/$src"/*; do
      name="$(basename "$item")"
      target="$DEST/$dst/$name"
      if [ -e "$target" ]; then
        log "Removing $dst/$name"
        rm -rf "$target"
      fi
    done
  done
  log "Done."
}

case "$ACTION" in
  install) do_install ;;
  remove) do_remove ;;
esac

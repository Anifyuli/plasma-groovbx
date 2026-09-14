#!/usr/bin/env bash
# Neither plasma-apply-colorscheme nor plasma-apply-lookandfeel reliably
# apply the [kdeglobals][General] AccentColor declared in a color scheme
# or Global Theme's defaults - AccentColor is a single global value, and
# switching between Plasma Groovbx Dark/Light via the normal System
# Settings UI can leave the *other* variant's AccentColor still in place,
# which then makes Plasma's own auto-contrast pick the wrong (often
# unreadable) Selection text color.
#
# Run this after switching between Plasma Groovbx Dark and Light to force
# the correct AccentColor for whichever one is active, and re-derive the
# colors that depend on it (Selection text, Pager, focus rings, ...).
set -e

scheme="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)"
case "$scheme" in
  PlasmaGroovbxDark)  accent="69,133,136";  other=BreezeDark ;;
  PlasmaGroovbxLight) accent="50,180,186"; other=BreezeDark ;;
  *)
    echo "Active color scheme is '$scheme', not a Plasma Groovbx variant - nothing to do." >&2
    exit 1
    ;;
esac

plasma-apply-colorscheme "$other" >/dev/null
kwriteconfig6 --file kdeglobals --group General --key AccentColor "$accent"
plasma-apply-colorscheme "$scheme" >/dev/null

rm -rf ~/.cache/plasma_theme_* ~/.cache/plasma-svgelements* ~/.cache/ksvg* 2>/dev/null || true
kquitapp6 plasmashell >/dev/null 2>&1 || true
sleep 1
setsid plasmashell >/dev/null 2>&1 &
disown

echo "AccentColor fixed for $scheme ($accent)."

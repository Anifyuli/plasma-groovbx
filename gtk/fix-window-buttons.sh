#!/usr/bin/env bash
# NOT part of the installable Plasma Groovbx package (color-schemes/, plasma/,
# wallpaper/, icons/). Nothing here runs automatically for anyone who installs
# the theme from KDE Store or otherwise - this is a personal, local workaround
# script, kept in-repo only for convenience.
#
# This used to be attributed to a plain kde-gtk-config/Wayland upstream bug
# (reproduced empty on one machine even with stock Breeze Dark). Turned out
# on at least some machines/Plasma versions the real cause was on our side:
# both `defaults` files had `library=org.kde.kwin.breeze` under
# [kwinrc][org.kde.kdecoration2] - not a real decoration plugin (the actual
# one, matching stock Breeze's own defaults, is `org.kde.breeze`). That
# bogus value could make KWin fail to load the decoration kde-gtk-config
# tries to export for GTK, coming back empty. Fixed in the `defaults` files;
# re-applying the theme fresh should write the correct library going
# forward. Kept this script around regardless as a manual fallback/repair
# tool in case the export still comes back empty for you.
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
#
# There's a second failure mode this script also has to cover: after
# populate() has run, the kde-gtk-config kded can export KWin's button
# states over these very files, and the export flattens each state's
# composited pixels into solid scheme-derived colors. Hover/active glyphs
# end up as e.g. #3c3836 (light-on-dark alpha-composited = muddy near-black)
# and render invisible on the dark titlebar - which is why the maximize
# button looked "black" right after clicking it (cursor parked on it puts
# it in hover). populate()+recolor_generated() force every state's glyph to
# the active titlebar foreground, so no state can go dark again.
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
    # Recolor the glyph of every state to the active titlebar foreground.
    # The glyph is the only group with stroke-linecap="round" (scaffolding
    # uses "square", the hover/active discs are fills); leave #000000 and
    # the close-hover red family alone here (close hover is set to red
    # below). Covers both fresh stock copies (#ffffff/#fefefe glyphs) and
    # kde-gtk-config's scheme-colored re-exports (e.g. #3c3836) so no
    # state can render dark on the titlebar.
    GLYPH_COLOR="$GLYPH_COLOR" perl -pi -e '
      if (/stroke-linecap="round"/) {
        if (/\bstroke="#([0-9a-fA-F]{6})"/) {
          my $c = lc $1;
          if ($c ne "000000" && $c !~ /^(ff0404|fb4934|ffb7ae|7d241a|da4453|ff4747)$/) {
            s/\bstroke="#\Q$c\E"/stroke="$ENV{GLYPH_COLOR}"/i;
          }
        }
      }
    ' "$dir"/*.svg
    # Fresh stock copies are single-path files with fill="#ffffff" (no
    # stroke groups at all) - recolor their only fill to the same glyph
    # color, keeping the stock close-hover red and any #000000 scaffolding.
    stock=($(grep -rL 'stroke-linecap="round"' "$dir"/*.svg 2>/dev/null || true))
    if [ "${#stock[@]}" -gt 0 ]; then
      GLYPH_COLOR="$GLYPH_COLOR" perl -0777 -pi -e '
        my $G = $ENV{GLYPH_COLOR};
        s{\bfill="#([0-9a-fA-F]{6})"}{lc($1) =~ /^(000000|ff0404|fb4934|ffb7ae|da4453|ff4747|7d241a)$/ ? qq(fill="#$1") : qq(fill="$G")}egi;
      ' "${stock[@]}"
    fi
    # Close hover is deliberately red (matches the tooltip pill assets).
    perl -pi -e '
      if (/stroke-linecap="round"/) {
        if (/\bstroke="#([0-9a-fA-F]{6})"/) {
          s/\bstroke="#\Q$1\E"/stroke="#fb4934"/i;
        }
      }
    ' "$dir"/close-hover.svg "$dir"/close-backdrop-hover.svg
  fi
}

populate "$HOME/.config/gtk-3.0/assets"
[ -d "$HOME/.config/gtk-4.0/assets" ] && populate "$HOME/.config/gtk-4.0/assets"
echo "GTK window button icons restored (glyph color: $GLYPH_COLOR)."

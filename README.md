# Plasma Groovbx

A Gruvbox-colored Global Theme for KDE Plasma 6 — Breeze's look and feel, kept
stock (icon style, layout, window decorations), with the color scheme, accent,
icons, and wallpaper swapped for [Gruvbox](https://github.com/morhetz/gruvbox).

## Screenshots

| Dark | Light |
|---|---|
| ![Plasma Groovbx Dark](plasma/look-and-feel/com.anifyuli.plasmagroovbxdark.desktop/contents/previews/preview.png) | ![Plasma Groovbx Light](plasma/look-and-feel/com.anifyuli.plasmagroovbxlight.desktop/contents/previews/preview.png) |

Wallpaper — *Circularities*, by Anifyuli:

| Dark | Light |
|---|---|
| ![Circularities dark](wallpaper/PlasmaGroovbxWallpaper/contents/images_dark/1920x1080.png) | ![Circularities light](wallpaper/PlasmaGroovbxWallpaper/contents/images/1920x1080.png) |

## Components

| Component | Location | Installs to |
|---|---|---|
| Color schemes (Dark/Light) | `color-schemes/` | `~/.local/share/color-schemes/` |
| Plasma style | `plasma/desktoptheme/` | `~/.local/share/plasma/desktoptheme/` |
| Global Theme (Dark/Light) | `plasma/look-and-feel/` | `~/.local/share/plasma/look-and-feel/` |
| Icons (Dark/Light) | `icons/` | `~/.local/share/icons/` |
| Yakuake skin | `yakuake/skins/` | `~/.local/share/yakuake/skins/` |
| Wallpaper | `wallpaper/` | `~/.local/share/wallpapers/` |

Each piece works on its own — the color schemes work with the default Breeze
icon theme, the icon theme works with any color scheme, etc. The Global
Theme entries just tie the matching set together and switch to it in one go
(picking the right icon theme for the mode automatically, same as stock
Breeze/Breeze Dark).

## Install

```sh
git clone https://github.com/Anifyuli/plasma-groovbx.git
cd plasma-groovbx
chmod +x install.sh
./install.sh
```

Add `-g`/`--gtk` to also apply the optional GTK extras (see below), `-d DIR`
to install somewhere other than `~/.local/share`, and `-r`/`--remove` to
uninstall (switches back to stock Breeze/Breeze Dark first if Plasma
Groovbx is the active Global Theme). `./install.sh --help` for the full
list.

Then apply from System Settings → Appearance → Global Themes → **Plasma
Groovbx Dark** or **Plasma Groovbx Light**.

Already had the theme installed and just pulled an update? `install.sh`
only copies files to `~/.local/share` — it doesn't re-apply the Global
Theme. Some fixes (wallpaper, window decoration, panel layout) only take
effect once the theme is actually re-applied, since that's what pushes
`defaults` into your live config (`~/.config/kdedefaults/`). Re-apply from
System Settings (or `plasma-apply-lookandfeel -a
com.anifyuli.plasmagroovbxdark.desktop`) after updating.

Prefer to do it by hand instead? Each component under `Components` above is
just a folder to copy to the matching path in `~/.local/share/`.

Yakuake doesn't pick up its skin automatically — open Yakuake, go to
Configure Yakuake → Appearance, and pick **Groovbx** from the Skin list.

## Icons

The icon theme is a full local copy of current Breeze (`Inherits=breeze,
breeze-dark,hicolor` is still declared, so anything that ever falls through —
a future Breeze icon this repo doesn't have yet — still resolves), plus:
- The third-party app icons that upstream Breeze
  [removed](https://invent.kde.org/frameworks/breeze-icons/-/merge_requests/477)
  are restored, and every app icon this project carries (LibreOffice, System
  Settings, Yakuake, Dolphin, and the rest of the restored third-party set)
  is re-tinted to the Gruvbox palette by hue-mapping its accent colors —
  neutral/near-black/near-white shading is left alone so icons stay
  recognizable.
- The network status icons (connected/disconnected/signal strength, wired
  and wireless) completed to match current Breeze, following the active
  color scheme automatically.
- A Gruvbox-tinted `fedora-logo-icon` (the Kickoff/menu icon on Fedora
  spins, whose default already resolves to that name — nothing in this repo
  forces it) alongside the existing tinted `start-here-kde`/
  `start-here-kde-plasma` for KDE's own generic menu mark on other distros.
- Folder and generic UI icons follow the accent color automatically (Breeze's
  own `ColorScheme-Accent` mechanism), no separate icon work needed there.

## Known issue: AccentColor after switching Dark ↔ Light

Neither `plasma-apply-colorscheme` nor `plasma-apply-lookandfeel` reliably
apply the AccentColor declared in a color scheme or Global Theme's
`defaults` — it's a single global value, and switching between Plasma
Groovbx Dark and Light from System Settings can leave the *other*
variant's AccentColor in place. Since Plasma derives the Selection text
color (and a few other things, like the Pager's active-desktop indicator)
from AccentColor at apply time, this can leave selected text unreadable.

If that happens, run:

```sh
./fix-accent-color.sh
```

## GTK apps

GTK3/4 apps are themed automatically by Plasma's own GTK Config integration
(same as with any KDE color scheme) — nothing in this repo is required for
that. `gtk/` in this repo is a couple of extra, optional files (not part of
the installed theme, not applied unless you pass `-g`/`--gtk` to
`install.sh` or copy them yourself):

- `gtk/gtk.css.append` — a small snippet some people may want to brighten the
  GTK titlebar close-button hover color; append it to your own
  `~/.config/gtk-3.0/gtk.css` / `gtk-4.0/gtk.css` if you want it.
- `gtk/fix-window-buttons.sh` — a workaround for a `kde-gtk-config` bug
  (reproduces with 100% stock Breeze, unrelated to this theme) where GTK
  window buttons render blank. Only needed if you hit that specific bug.
  Glyph color is read from the active scheme's own `[WM] activeForeground`
  at run time, so it looks right on both Dark and Light (and re-running it
  after switching Dark ↔ Light picks up the new color).

- `gtk/fix-gtk-sync.sh` — for when `kde-gtk-config` never finished syncing
  GTK for the session at all: `~/.config/gtk-3.0/settings.ini` missing
  `window-decorations-gtk-module` from `gtk-modules=`, and/or no
  `gtk-theme-name=` set. Symptom: most GTK theming looks right, but
  individual CSD buttons render in the wrong/unreadable color in some apps
  (seen with Remmina's maximize/restore button) since they never got
  Breeze's own titlebutton styling. Only patches what's missing/empty —
  won't override a `gtk-theme-name` you've set deliberately. **Log out and
  back in** afterward; restarting `kded6` alone isn't enough to re-init the
  handshake with already-running apps.

## License

[GPL-3.0-or-later](LICENSE), except the Plasma style
(`plasma/desktoptheme/`), inherited as [LGPL](plasma/desktoptheme/LICENSE)
from Breeze.

#!/usr/bin/env python3
"""Recolour icons into both Plasma Groovbx variants with the Gruvbox tint.

  tint.py table              rebuild tools/colour-table.json from the tree vs stock Breeze
  tint.py app NAME...        tint an installed app's icon (hicolor/Flatpak) into apps/48
  tint.py file SRC REL       tint SRC into icons/<variant>/REL, e.g. a breeze-third-party
                             icon: tint.py file ~/btp/icons/actions/22/im-foo.svg actions/22/im-foo.svg

Run from the repo root. Colours found in the table map exactly; anything else
follows a smooth hue curve fitted to the table (lightness kept, greys left
alone). PNG sources need PySide6.
"""
import argparse, collections, colorsys, glob, json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TABLE = os.path.join(HERE, 'colour-table.json')
VARIANTS = {'PlasmaGroovbx': 'breeze-dark', 'PlasmaGroovbxLight': 'breeze'}
ICON_ROOTS = ['/usr/share/icons/hicolor', '/var/lib/flatpak/exports/share/icons/hicolor',
              os.path.expanduser('~/.local/share/flatpak/exports/share/icons/hicolor')]
HEX = re.compile(r'#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b')


def canon(h):
    h = h.lower()
    return ''.join(c * 2 for c in h) if len(h) == 3 else h


def hls(c):
    return colorsys.rgb_to_hls(*(int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)))


def build_table():
    """Most common tinted colour per Breeze colour, per category (apps, actions, ...)."""
    out = {}
    for variant, breeze in VARIANTS.items():
        pairs = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
        root = f'/usr/share/icons/{breeze}'
        for d, _, fs in os.walk(root):
            for f in fs:
                src = os.path.join(d, f)
                if not f.endswith('.svg') or os.path.islink(src):
                    continue
                rel = os.path.relpath(src, root)
                ours = f'icons/{variant}/{rel}'
                if os.path.islink(ours) or not os.path.exists(ours):
                    continue
                a = [canon(m)[:6] for m in HEX.findall(open(src, errors='ignore').read())]
                b = [canon(m)[:6] for m in HEX.findall(open(ours, errors='ignore').read())]
                if len(a) == len(b):
                    for x, y in zip(a, b):
                        pairs[rel.split('/')[0]][x][y] += 1
        out[variant] = {cat: {k: v.most_common(1)[0][0] for k, v in sorted(p.items())}
                        for cat, p in sorted(pairs.items())}
    json.dump(out, open(TABLE, 'w'), indent=0, sort_keys=True)
    print({v: sum(len(t) for t in c.values()) for v, c in out.items()}, 'colours ->', TABLE)


_curves = {}


def curve(key, table):
    """Hue -> (target hue, saturation ratio), Gaussian-smoothed over the table,
    so neighbouring colours move together and gradients don't band."""
    if key in _curves:
        return _curves[key]
    pts = []
    for s_, t_ in table.items():
        sh, sl, ss = hls(s_)
        th, tl, ts = hls(t_)
        if ss > 0.25 and 0.15 < sl < 0.85 and abs(tl - sl) < 0.2:
            pts.append((sh, th, ts / ss))
    out = []
    for b in range(360):
        h = b / 360
        wx = wy = wr = wsum = 0
        for sh, th, r in pts:
            d = min(abs(h - sh), 1 - abs(h - sh)) * 360
            w = math.exp(-(d / 12) ** 2)
            wx += w * math.cos(2 * math.pi * th)
            wy += w * math.sin(2 * math.pi * th)
            wr += w * r
            wsum += w
        out.append((math.atan2(wy, wx) / (2 * math.pi) % 1, min(1.2, wr / wsum)) if wsum > 1e-6 else (h, 1))
    _curves[key] = out
    return out


def shift(c, key, table):
    # ponytail: fitted hue curve, not the original hand-anchored tint; exact
    # table hits still win for SVG colours.
    h, l, s = hls(c)
    th, ratio = curve(key, table)[int(h * 360) % 360]
    w = min(1, max(0, (s - 0.08) / 0.15))
    nh = (h + w * (((th - h + 0.5) % 1) - 0.5)) % 1
    r, g, b = colorsys.hls_to_rgb(nh, l, min(1, s * (1 + w * (ratio - 1))))
    return '%02x%02x%02x' % tuple(round(x * 255) for x in (r, g, b))


def tint_svg(text, key, table, dark):
    if dark:
        # Light-only sources (breeze-third-party, hicolor): breeze-dark is built
        # by swapping the stylesheet's text colour, so do the same first.
        text = re.sub(r'<style[^>]*current-color-scheme.*?</style>',
                      lambda m: re.sub('#232629', '#fcfcfc', m.group(0), flags=re.I), text, flags=re.S)

    def sub(m):
        c = canon(m.group(1))
        return '#' + (table.get(c[:6]) or shift(c[:6], key, table)) + c[6:]
    return HEX.sub(sub, text)


def tint_png(src, dst, key, table):
    from PySide6.QtGui import QColor, QGuiApplication, QImage
    QGuiApplication.instance() or QGuiApplication([])
    img, memo = QImage(src).convertToFormat(QImage.Format_ARGB32), {}
    for y in range(img.height()):
        for x in range(img.width()):
            c = img.pixelColor(x, y)
            if c.alpha():
                px = '%02x%02x%02x' % (c.red(), c.green(), c.blue())
                n = memo.get(px) or memo.setdefault(px, shift(px, key, table))
                img.setPixelColor(x, y, QColor(int(n[:2], 16), int(n[2:4], 16), int(n[4:], 16), c.alpha()))
    img.save(dst)


def tint_file(src, rel):
    tables = json.load(open(TABLE))
    src = os.path.realpath(src)  # Flatpak exports are symlinks
    for variant in VARIANTS:
        cat = rel.split('/')[0] if rel.split('/')[0] in tables[variant] else 'apps'
        table, key = tables[variant][cat], (variant, cat)
        dst = f'icons/{variant}/{rel}'
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.lexists(dst):
            os.remove(dst)
        if src.endswith('.png'):
            tint_png(src, dst, key, table)
        else:
            open(dst, 'w').write(tint_svg(open(src).read(), key, table, variant == 'PlasmaGroovbx'))
        print(dst)


def app_source(name):
    """Scalable SVG if the app ships one, else its largest PNG up to 512px."""
    for root in ICON_ROOTS:
        if os.path.exists(f'{root}/scalable/apps/{name}.svg'):
            return f'{root}/scalable/apps/{name}.svg'
    size = lambda p: int(p.split('/')[-3].split('x')[0])
    pngs = [p for r in ICON_ROOTS for p in glob.glob(f'{r}/*x*/apps/{name}.png') if size(p) <= 512]
    return max(pngs, key=size) if pngs else None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('table')
    a = sub.add_parser('app')
    a.add_argument('names', nargs='+')
    f = sub.add_parser('file')
    f.add_argument('src')
    f.add_argument('rel')
    args = ap.parse_args()
    if not os.path.isdir('icons/PlasmaGroovbx'):
        sys.exit('run from the repo root')
    if args.cmd == 'table':
        build_table()
    elif args.cmd == 'file':
        tint_file(args.src, args.rel)
    else:
        for name in args.names:
            src = app_source(name)
            if not src:
                print(f'{name}: no icon in hicolor or Flatpak exports', file=sys.stderr)
                continue
            tint_file(src, f'apps/48/{name}.{src.rsplit(".", 1)[1]}')


if __name__ == '__main__':
    main()

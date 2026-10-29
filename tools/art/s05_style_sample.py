"""S05 style sample: build the normal layer and the Blue Lake layer for the 《窗》 wall.

Usage (from the project root):
    python3 tools/art/s05_style_sample.py --raw art/raw --out assets/style_sample

Inputs  : art/raw/museum2/IMG_1897.JPG (wall + floor)
Outputs : 2304x1296 PNGs (2x the 1152x648 game view)
    s05_normal.png            normal world, lights off, 《窗》 glowing warm
    s05_normal_handle.png     overlay: brass handle on the frame (after the first chalk touch)
    s05_normal_open.png       overlay: the painting opened (leads to the central platform)
    s05_bluelake.png          Blue Lake world: #0078D7 + chalk edges + code
    s05_bluelake_handle.png   overlay: chalk handle + opening seam
    s05_bluelake_open.png     overlay: chalk leaves swung open
    s05_layout.json           where the window sits, in game (1x) coordinates

The 《窗》 painting is drawn procedurally (pointed-arch window inspired by the *shape*
of art/raw/窗/IMG_1871.JPG; none of that photo's glass designs are copied).
"""
import argparse, json, math, os
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT_W, OUT_H = 2304, 1296          # 2x of 1152x648
SCALE = OUT_W / 1152
BLUE = np.array([215, 120, 0], np.float32)   # #0078D7 in BGR
RNG = np.random.default_rng(1897)

# ---- layout in game coordinates (1x) ---------------------------------------------
WIN_CENTER = (590, 300)
WIN_SIZE = (150, 210)               # outer frame size
FRAME = 8                           # frame thickness
WALL_BASE_Y = 524                   # wall meets floor
FLOOR_TOP, FLOOR_BOTTOM = 485, 570  # Graham's origin range (placeholder body hangs below it)

CODE = """# S05 《窗》
func observe(painting) -> String:
    return "a painting"           # 你把它看成一幅画
func observe_again(painting):
    return painting.another_possible_form()
var handle = painting.frame.find("handle")
# 把手一直在那里。只是你以前看不见。
assert(handle != null)
painting.open()                   # 你把一幅画……打开了
# 这不是出口。
if seeing != being: pass
""".splitlines()


def g(v):
    """game (1x) -> output (2x) pixels"""
    return int(round(v * SCALE))


# ---------------------------------------------------------------------------------
# 1. plate: perspective-correct the wall photo and remove the two artworks
# ---------------------------------------------------------------------------------
def build_plate(raw_dir):
    im = cv2.imread(os.path.join(raw_dir, "museum2", "IMG_1897.JPG"))
    k = im.shape[1] / 1400          # all hand-picked coordinates are on a 1400px-wide copy
    src = np.float32([(267, 250), (1175, 250), (1232, 742), (231, 760)]) * k
    dst = np.float32([(231, 250), (1232, 250), (1232, 751), (231, 751)]) * k
    H = cv2.getPerspectiveTransform(src, dst)
    im = cv2.warpPerspective(im, H, (im.shape[1], im.shape[0]), flags=cv2.INTER_CUBIC,
                             borderMode=cv2.BORDER_REPLICATE).astype(np.float32)
    orig = im.copy()
    R = lambda v: int(round(v * k))

    def fill(img, x0, x1, y0, y1, dx, feather=1.5):
        low = cv2.GaussianBlur(img, (0, 0), R(3)); high = img - low
        a, b, c, d = R(x0), R(x1), R(y0), R(y1); pad = R(4)
        L = low[c:d, a - pad * 3:a - pad].mean(axis=1)
        Rt = low[c:d, b + pad:b + pad * 3].mean(axis=1)
        t = np.linspace(0, 1, b - a)[None, :, None]
        patch = L[:, None, :] * (1 - t) + Rt[:, None, :] * t + high[c:d, a + R(dx):b + R(dx)]
        m = np.zeros(img.shape[:2], np.float32); m[c:d, a:b] = 1
        m = cv2.GaussianBlur(m, (0, 0), R(feather))
        full = img.copy(); full[c:d, a:b] = patch
        return img * (1 - m[..., None]) + full * m[..., None]

    # cage sculpture: wall part, then the baseboard/floor band with clean texture donors
    im = fill(im, 872, 1112, 600, 736, -260, 4)
    im = fill(im, 872, 1112, 732, 795, 0)
    low = cv2.GaussianBlur(im, (0, 0), R(3))
    oh = orig - cv2.GaussianBlur(orig, (0, 0), R(3))
    c, d = R(732), R(795)
    for x0, x1, dx in ((872, 992, -150), (992, 1112, 110)):
        a, b = R(x0), R(x1)
        im[c:d, a:b] = low[c:d, a:b] + oh[c:d, a + R(dx):b + R(dx)]
    im = fill(im, 458, 516, 722, 785, 90)           # stone sculpture

    # 16:9 crop that puts the wall's centre at game x=590
    x0, x1, y0, y1 = R(55), R(1375), R(150), R(893)
    im = im[y0:y1, x0:x1]
    im = cv2.resize(np.clip(im, 0, 255).astype(np.uint8), (OUT_W, OUT_H), interpolation=cv2.INTER_AREA)
    return im


# ---------------------------------------------------------------------------------
# 2. the painting 《窗》
# ---------------------------------------------------------------------------------
def arch_profile(w, spring):
    """x offsets of a pointed (equilateral-style) arch: for each dy above the spring line,
    the arch spans [xl, w - xl]. Apex sits `spring` px above the spring line."""
    s = 0.866 * w / spring
    def xl(dy_px):
        dy = np.clip(dy_px * s, 0, 0.866 * w)
        return w - np.sqrt(np.maximum(w * w - dy * dy, 0))
    return xl


def arch_mask(w, h, spring):
    """pointed arch filling a w x h box; the arch occupies the top `spring` px."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    xl = arch_profile(w, spring)(spring - yy)
    inside = (xx >= xl) & (xx <= w - xl)
    inside[int(spring):] = True
    return inside.astype(np.float32)


def paint_window(state):
    """Returns RGBA float image of the framed painting (2x), plus the glass mask."""
    W, H = g(WIN_SIZE[0]), g(WIN_SIZE[1]); F = g(FRAME)
    iw, ih = W - 2 * F, H - 2 * F
    yy, xx = np.mgrid[0:ih, 0:iw].astype(np.float32)
    # painted interior: a dark room, warmer near the floor
    top = np.array([40, 34, 26], np.float32); bot = np.array([30, 40, 52], np.float32)
    bg = top + (bot - top) * (yy / ih)[..., None]
    n = cv2.GaussianBlur(RNG.random((ih, iw)).astype(np.float32), (0, 0), 3)
    bg *= (0.8 + 0.4 * n)[..., None]
    # the lancet
    lw, lh = int(iw * 0.52), int(ih * 0.74)
    lx, ly = (iw - lw) // 2, int(ih * 0.08)
    glass = np.zeros((ih, iw), np.float32)
    glass[ly:ly + lh, lx:lx + lw] = arch_mask(lw, lh, int(lw * 0.85))
    if state == "open":
        # casements swung inward: the opening shows a cold, deeper room (the central platform)
        deep = np.array([70, 40, 18], np.float32) + np.array([90, 60, 20], np.float32) * (1 - yy / ih)[..., None]
        cx = iw / 2; spot = np.exp(-(((xx - cx) / (lw * 0.25)) ** 2 + ((yy - ly - lh * 0.75) / (lh * 0.18)) ** 2))
        deep += np.array([150, 120, 80], np.float32) * spot[..., None]
        # pedestal far behind, caught in the spot
        ped = ((np.abs(xx - cx) < lw * 0.1) & (yy > ly + lh * 0.74) & (yy < ly + lh * 0.98)).astype(np.float32)
        ped_top = ((np.abs(xx - cx) < lw * 0.13) & (yy > ly + lh * 0.72) & (yy < ly + lh * 0.75)).astype(np.float32)
        deep = deep * (1 - ped[..., None]) + np.array([95, 90, 85], np.float32) * ped[..., None]
        deep = deep * (1 - ped_top[..., None]) + np.array([200, 205, 210], np.float32) * ped_top[..., None]
        inner = bg * (1 - glass[..., None]) + deep * glass[..., None]
        # the two leaves swung inward: narrow, foreshortened, still holding warm glass
        leaf = np.zeros_like(glass)
        lwid = int(lw * 0.13)
        leaf[ly + int(lh * 0.2):ly + lh, lx:lx + lwid] = 1
        leaf[ly + int(lh * 0.2):ly + lh, lx + lw - lwid:lx + lw] = 1
        leaf *= glass
        lgrid = ((((yy - ly) % 9) < 1.2) | (np.abs(xx - lx - lwid / 2) < 0.8) | (np.abs(xx - (lx + lw - lwid / 2)) < 0.8)).astype(np.float32)
        lcol = np.array([45, 115, 190], np.float32) * (0.75 + 0.35 * (1 - (yy - ly) / lh))[..., None]
        lcol = lcol * (1 - 0.7 * lgrid[..., None])
        inner = inner * (1 - leaf[..., None]) + lcol * leaf[..., None]
    else:
        warm = np.array([60, 150, 235], np.float32); hot = np.array([165, 225, 255], np.float32)
        c = np.exp(-(((xx - iw / 2) / (lw * 0.42)) ** 2 + ((yy - ly - lh * 0.42) / (lh * 0.45)) ** 2))
        lit = warm + (hot - warm) * c[..., None]
        step = max(5, lw // 12); stepy = int(step * 1.35)
        # hand-made glass: every pane a little different
        pi = ((xx - lx) // step).astype(int); pj = ((yy - ly) // stepy).astype(int)
        var = np.random.default_rng(7).uniform(0.62, 1.15, (64, 64)).astype(np.float32)
        lit *= var[np.clip(pj, 0, 63), np.clip(pi, 0, 63)][..., None]
        tint_cols = [np.array([40, 40, 150], np.float32), np.array([150, 70, 30], np.float32), np.array([60, 120, 60], np.float32)]
        pick = np.random.default_rng(11).integers(0, 8, (64, 64))
        sel = pick[np.clip(pj, 0, 63), np.clip(pi, 0, 63)]
        upper = yy < ly + lh * 0.42
        for k_, col in enumerate(tint_cols):
            m_ = ((sel == k_) & upper)[..., None]
            lit = np.where(m_, lit * 0.3 + col * 0.95, lit)
        lead = np.zeros((ih, iw), np.float32)
        lead[(((xx - lx) % step) < 1.2) | (((yy - ly) % stepy) < 1.2)] = 0.8
        lead[:, int(iw / 2 - 2):int(iw / 2 + 2)] = 1
        for t in (0.42, 0.66):
            lead[int(ly + lh * t) - 2:int(ly + lh * t) + 2, :] = 1
        cyc, r = ly + lh * 0.22, lw * 0.17
        dist = np.hypot(xx - iw / 2, yy - cyc)
        lead[np.abs(dist - r) < 2.2] = 1
        lead[dist < r - 2.2] *= 0.2
        lit = lit * (1 - 0.8 * lead[..., None]) + np.array([18, 22, 28], np.float32) * 0.8 * lead[..., None]
        # light falling on the painted floor under the window
        spread = lw * 0.5 + np.maximum(yy - ly - lh, 0) * 1.2
        fl = np.clip(1 - np.abs(xx - iw / 2) / spread, 0, 1) * (yy > ly + lh)
        bg = bg + np.array([60, 110, 150], np.float32) * (fl * 0.6)[..., None]
        inner = bg * (1 - glass[..., None]) + lit * glass[..., None]
        bloom = cv2.GaussianBlur(glass, (0, 0), g(9))
        inner += np.array([60, 120, 170], np.float32) * bloom[..., None] * 0.9
    # oil-paint feel: soften, posterise into strokes, add brush marks and canvas tooth
    inner = cv2.GaussianBlur(np.clip(inner, 0, 255), (0, 0), 0.9)
    inner = kuwahara(inner, 4)
    inner = kuwahara(inner, 2)
    inner *= (1 + 0.07 * brush_texture(ih, iw, 5))[..., None]
    if state != "open":
        # re-paint the stone mullion, transoms and tracery ring as soft dark strokes
        st = np.zeros((ih, iw), np.float32)
        st[ly + int(lh * 0.36):ly + lh, int(iw / 2 - 2.5):int(iw / 2 + 2.5)] = 1
        for t in (0.42, 0.66):
            st[int(ly + lh * t) - 2:int(ly + lh * t) + 2, lx:lx + lw] = 1
        dist = np.hypot(xx - iw / 2, yy - (ly + lh * 0.22))
        st[np.abs(dist - lw * 0.17) < 2.5] = 1
        st = cv2.GaussianBlur(st * glass, (0, 0), 0.9) * (0.75 + 0.25 * np.clip(brush_texture(ih, iw, 9), -1, 1))
        inner = inner * (1 - 0.78 * st[..., None]) + np.array([22, 26, 32], np.float32) * 0.78 * st[..., None]
    canvas_grain = cv2.GaussianBlur(RNG.random((ih, iw)).astype(np.float32), (0, 0), 0.7)
    inner *= (0.94 + 0.1 * canvas_grain)[..., None]
    # frame: dark wood with a thin worn gilt edge
    out = np.zeros((H, W, 3), np.float32) + np.array([28, 36, 48], np.float32)
    fy, fx = np.mgrid[0:H, 0:W]
    edge = np.minimum.reduce([fx, fy, W - 1 - fx, H - 1 - fy]).astype(np.float32)
    out[(edge > F - 3) & (edge <= F - 1)] = (90, 130, 160)
    out[edge < 2] = (18, 22, 30)
    wood = cv2.GaussianBlur(RNG.random((H, W)).astype(np.float32), (0, 0), sigmaX=1, sigmaY=6)
    out *= (0.8 + 0.4 * wood)[..., None]
    out[F:F + ih, F:F + iw] = inner
    # inner shadow from the frame
    sh = np.zeros((H, W), np.float32); sh[F:F + ih, F:F + iw] = 1
    sh = 1 - cv2.GaussianBlur(1 - sh, (0, 0), 4) * sh
    out[F:F + ih, F:F + iw] *= sh[F:F + ih, F:F + iw, None] ** 1.5
    g_full = np.zeros((H, W), np.float32); g_full[F:F + ih, F:F + iw] = glass
    return out, g_full


def kuwahara(img, r=3):
    """painterly smoothing: each pixel takes the mean of its calmest quadrant"""
    img = img.astype(np.float32); k = r + 1
    lum = img.mean(-1)
    best_m = None; best_v = None
    for ax, ay in ((0, 0), (r, 0), (0, r), (r, r)):
        m = cv2.blur(img, (k, k), anchor=(ax, ay), borderType=cv2.BORDER_REFLECT)
        ml = cv2.blur(lum, (k, k), anchor=(ax, ay), borderType=cv2.BORDER_REFLECT)
        v = cv2.blur(lum * lum, (k, k), anchor=(ax, ay), borderType=cv2.BORDER_REFLECT) - ml * ml
        if best_m is None:
            best_m, best_v = m, v
        else:
            sel = (v < best_v)[..., None]
            best_m = np.where(sel, m, best_m); best_v = np.minimum(v, best_v)
    return best_m


def brush_texture(h, w, seed):
    """streaky, mostly vertical brush marks"""
    rng = np.random.default_rng(seed)
    n = rng.random((h, w)).astype(np.float32)
    a = cv2.GaussianBlur(n, (0, 0), sigmaX=0.8, sigmaY=5)
    b = cv2.GaussianBlur(rng.random((h, w)).astype(np.float32), (0, 0), sigmaX=4, sigmaY=1)
    t = 0.65 * a + 0.35 * b
    return (t - t.mean()) / (t.std() + 1e-6)


def paste(dst, src, cx, cy, alpha=None):
    h, w = src.shape[:2]; x0, y0 = cx - w // 2, cy - h // 2
    if alpha is None:
        dst[y0:y0 + h, x0:x0 + w] = src
    else:
        a = alpha[..., None]
        dst[y0:y0 + h, x0:x0 + w] = dst[y0:y0 + h, x0:x0 + w] * (1 - a) + src * a
    return dst


def radial(cx, cy, rx, ry):
    yy, xx = np.mgrid[0:OUT_H, 0:OUT_W].astype(np.float32)
    return np.exp(-(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2))


# ---------------------------------------------------------------------------------
# 3. normal layer
# ---------------------------------------------------------------------------------
def grade_cold_dim(plate):
    f = plate.astype(np.float32) / 255
    lum = f.mean(-1, keepdims=True)
    f = lum + (f - lum) * 0.55                      # desaturate
    f = f * np.array([1.10, 0.95, 0.80])            # cool (BGR)
    f = 0.06 + f * 0.48                             # lights off: lift blacks, drop highlights
    yy, xx = np.mgrid[0:OUT_H, 0:OUT_W].astype(np.float32)
    v = 1 - 0.45 * (((xx - OUT_W / 2) / (OUT_W * 0.62)) ** 2 + ((yy - OUT_H * 0.55) / (OUT_H * 0.75)) ** 2)
    f *= np.clip(v, 0.35, 1)[..., None]
    return f * 255


def grain(img, amt=7):
    n = RNG.normal(0, amt, img.shape[:2]).astype(np.float32)
    return img + n[..., None]


def build_normal(plate):
    base = grade_cold_dim(plate)
    cx, cy = g(WIN_CENTER[0]), g(WIN_CENTER[1])
    W, H = g(WIN_SIZE[0]), g(WIN_SIZE[1])
    # the painting throws real light onto a real wall
    halo = radial(cx, cy, W * 1.25, H * 0.95)
    base += np.array([40, 85, 120], np.float32) * halo[..., None]
    # polished concrete picks up a smeared reflection under it
    floor_y = g(WALL_BASE_Y)
    refl = radial(cx, floor_y + g(40), W * 0.55, g(55)) * (np.mgrid[0:OUT_H, 0:OUT_W][0] > floor_y)
    base += np.array([30, 60, 90], np.float32) * refl[..., None]
    # drop shadow, then the painting
    sh = np.zeros(base.shape[:2], np.float32)
    sh[cy - H // 2 + g(4):cy + H // 2 + g(6), cx - W // 2 + g(3):cx + W // 2 + g(3)] = 1
    sh = cv2.GaussianBlur(sh, (0, 0), g(5))
    base *= (1 - 0.35 * sh)[..., None]
    painting, _ = paint_window("closed")
    base = paste(base, painting, cx, cy)
    return np.clip(grain(base, 6), 0, 255).astype(np.uint8)


def handle_normal():
    """RGBA overlay: a small brass lever on the frame's right edge."""
    lay = Image.new("RGBA", (OUT_W, OUT_H), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    cx = g(WIN_CENTER[0] + WIN_SIZE[0] / 2 - FRAME / 2); cy = g(WIN_CENTER[1] + 6)
    d.rounded_rectangle([cx - g(3), cy - g(9), cx + g(3), cy + g(9)], radius=g(2), fill=(120, 96, 52, 255))
    d.rounded_rectangle([cx - g(2), cy - g(2), cx + g(14), cy + g(3)], radius=g(2), fill=(196, 160, 88, 255))
    d.ellipse([cx + g(11), cy - g(3), cx + g(17), cy + g(4)], fill=(222, 190, 120, 255))
    d.line([cx - g(1), cy - g(7), cx - g(1), cy + g(5)], fill=(240, 220, 170, 200), width=2)
    glow = lay.filter(ImageFilter.GaussianBlur(g(6)))
    out = Image.alpha_composite(Image.new("RGBA", lay.size, (0, 0, 0, 0)), glow)
    return Image.alpha_composite(out, lay)


def open_normal():
    """RGBA overlay: the painting is now an opening; cold light comes out of it."""
    cx, cy = g(WIN_CENTER[0]), g(WIN_CENTER[1])
    painting, _ = paint_window("open")
    rgb = np.zeros((OUT_H, OUT_W, 3), np.float32); a = np.zeros((OUT_H, OUT_W), np.float32)
    h, w = painting.shape[:2]
    rgb[cy - h // 2:cy - h // 2 + h, cx - w // 2:cx - w // 2 + w] = painting
    a[cy - h // 2:cy - h // 2 + h, cx - w // 2:cx - w // 2 + w] = 1
    # cold spill on wall and floor
    spill = radial(cx, cy, w * 1.3, h * 1.0) * 0.45
    floor = radial(cx, g(WALL_BASE_Y) + g(60), w * 0.9, g(70)) * (np.mgrid[0:OUT_H, 0:OUT_W][0] > g(WALL_BASE_Y)) * 0.5
    glow = np.maximum(spill, floor) * (1 - a)
    rgb = rgb * a[..., None] + np.array([255, 200, 150], np.float32) * glow[..., None]
    alpha = np.clip(a + glow * 0.55, 0, 1)
    return to_rgba(rgb, alpha)


def to_rgba(bgr, alpha):
    rgb = np.clip(bgr[..., ::-1], 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb, (np.clip(alpha, 0, 1) * 255).astype(np.uint8)]), "RGBA")


# ---------------------------------------------------------------------------------
# 4. Blue Lake layer
# ---------------------------------------------------------------------------------
def chalk_texture(mask, keep=0.62, soft=0.6):
    n = RNG.random(mask.shape).astype(np.float32)
    n = cv2.GaussianBlur(n, (0, 0), soft)
    grain_ = np.clip((n - (1 - keep)) / 0.25, 0, 1)
    return mask * grain_


def chalk_lines(lines, width=3, jitter=1.2):
    """lines: list of polylines in output pixels -> chalky alpha mask"""
    lay = Image.new("L", (OUT_W, OUT_H), 0); d = ImageDraw.Draw(lay)
    for pts in lines:
        for _ in range(2):
            jp = [(x + RNG.normal(0, jitter), y + RNG.normal(0, jitter)) for x, y in pts]
            d.line(jp, fill=200, width=width, joint="curve")
    m = np.asarray(lay, np.float32) / 255
    return chalk_texture(cv2.GaussianBlur(m, (0, 0), 0.6), keep=0.7)


def arch_outline(cx, top, bottom, half_w, spring_frac=0.85):
    """polyline points for the same pointed arch as arch_mask, output px"""
    w = half_w * 2; spring = w * spring_frac; xl = arch_profile(w, spring)
    sy = top + spring
    left = [(cx - half_w + float(xl(dy)), sy - dy) for dy in np.linspace(0, spring, 24)]
    right = [(cx + half_w - float(xl(dy)), sy - dy) for dy in np.linspace(spring, 0, 24)]
    return [(cx - half_w, bottom)] + left + right + [(cx + half_w, bottom)]


def window_geometry():
    cx, cy = g(WIN_CENTER[0]), g(WIN_CENTER[1]); W, H = g(WIN_SIZE[0]), g(WIN_SIZE[1]); F = g(FRAME)
    iw, ih = W - 2 * F, H - 2 * F
    lw, lh = int(iw * 0.52), int(ih * 0.74)
    x0, y0 = cx - W // 2 + F, cy - H // 2 + F
    lx, ly = x0 + (iw - lw) // 2, y0 + int(ih * 0.08)
    return dict(cx=cx, cy=cy, W=W, H=H, F=F, lx=lx, ly=ly, lw=lw, lh=lh)


def code_layer(rect, size=19, hole=None):
    lay = Image.new("L", (OUT_W, OUT_H), 0); d = ImageDraw.Draw(lay)
    try:
        f = ImageFont.truetype("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", size, index=7)
    except OSError:
        f = ImageFont.load_default()
    x0, y0, x1, y1 = rect; y = y0; i = 0
    while y < y1:
        row = "    ".join(CODE[(i + j * 5) % len(CODE)].strip() for j in range(8))
        d.text((x0 - (i * 61) % 240, y), row, fill=255, font=f)
        y += int(size * 1.7); i += 1
    m = np.asarray(lay, np.float32) / 255
    clip = np.zeros_like(m); clip[y0:y1, x0:x1] = 1
    if hole:
        hx0, hy0, hx1, hy1 = hole; clip[hy0:hy1, hx0:hx1] = 0
        clip = cv2.GaussianBlur(clip, (0, 0), 6)
    return m * clip


def build_bluelake(plate):
    gray = cv2.cvtColor(plate, cv2.COLOR_BGR2GRAY)
    gray = cv2.bilateralFilter(gray, 9, 40, 9)
    edges = cv2.Canny(gray, 18, 55).astype(np.float32) / 255
    # drop speckle: keep only connected edges longer than ~40px
    num, lab, stats, _ = cv2.connectedComponentsWithStats((edges > 0).astype(np.uint8), 8)
    keep = np.zeros(num, bool); keep[1:] = np.maximum(stats[1:, 2], stats[1:, 3]) > 40
    edges = keep[lab].astype(np.float32)
    edges = cv2.dilate(edges, np.ones((3, 3), np.uint8))
    edges = chalk_texture(cv2.GaussianBlur(edges, (0, 0), 0.8), keep=0.68)
    # base: blue, with a ghost of the room's light so it keeps its depth
    lum = cv2.GaussianBlur(gray.astype(np.float32) / 255, (0, 0), 6)
    base = BLUE[None, None, :] * (0.72 + 0.45 * lum)[..., None]
    yy = np.mgrid[0:OUT_H, 0:OUT_W][0].astype(np.float32)
    base *= (1 - 0.18 * (yy / OUT_H))[..., None]
    white = np.array([250, 245, 240], np.float32)
    base = base * (1 - 0.85 * edges[..., None]) + white * 0.85 * edges[..., None]
    # faint code on the wall
    G = window_geometry(); cx, cy, W, H = G["cx"], G["cy"], G["W"], G["H"]
    wall = (g(160), g(150), g(1025), g(515))
    hole = (cx - W // 2 - g(24), cy - H // 2 - g(24), cx + W // 2 + g(24), cy + H // 2 + g(24))
    code = code_layer(wall, size=g(9), hole=hole)
    base = base * (1 - 0.11 * code[..., None]) + white * 0.11 * code[..., None]
    # the painting, redrawn in chalk; the glass is hatched so it reads as a surface
    lines = [[(cx - W // 2, cy - H // 2), (cx + W // 2, cy - H // 2), (cx + W // 2, cy + H // 2), (cx - W // 2, cy + H // 2), (cx - W // 2, cy - H // 2)]]
    F = G["F"]
    lines.append([(cx - W // 2 + F, cy - H // 2 + F), (cx + W // 2 - F, cy - H // 2 + F), (cx + W // 2 - F, cy + H // 2 - F), (cx - W // 2 + F, cy + H // 2 - F), (cx - W // 2 + F, cy - H // 2 + F)])
    half = G["lw"] // 2; top, bottom = G["ly"], G["ly"] + G["lh"]
    lines.append(arch_outline(cx, top, bottom, half))
    lines.append([(cx, top + G["lh"] * 0.38), (cx, bottom)])
    for t in (0.42, 0.66):
        y = top + G["lh"] * t; lines.append([(cx - half, y), (cx + half, y)])
    r = G["lw"] * 0.17; cyc = top + G["lh"] * 0.22
    lines.append([(cx + r * math.cos(a), cyc + r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 40)])
    win = chalk_lines(lines, width=4)
    hatch = Image.new("L", (OUT_W, OUT_H), 0); hd = ImageDraw.Draw(hatch)
    for k in range(-2 * H, 2 * W, g(7)):
        hd.line([(cx - W + k, cy + H), (cx - W + k + 2 * H, cy - H)], fill=110, width=2)
    am = np.zeros((OUT_H, OUT_W), np.float32)
    am[G["ly"]:G["ly"] + G["lh"], G["lx"]:G["lx"] + G["lw"]] = arch_mask(G["lw"], G["lh"], int(G["lw"] * 0.85))
    hatch = chalk_texture(np.asarray(hatch, np.float32) / 255 * am, keep=0.5)
    m = np.clip(win + hatch * 0.6, 0, 1)
    base = base * (1 - m[..., None]) + white * m[..., None]
    return np.clip(grain(base, 4), 0, 255).astype(np.uint8)


def handle_bluelake():
    G = window_geometry(); cx, cy, W, H = G["cx"], G["cy"], G["W"], G["H"]
    hx = cx + W // 2 - G["F"] // 2; hy = cy + g(6)
    lines = [
        [(hx - g(3), hy - g(12)), (hx + g(3), hy - g(12)), (hx + g(3), hy + g(12)), (hx - g(3), hy + g(12)), (hx - g(3), hy - g(12))],
        [(hx, hy), (hx + g(20), hy)],
        [(hx + g(20), hy - g(4)), (hx + g(20), hy + g(4))],
    ]
    # the opening seam: a dashed line down the middle of the lancet
    top, bottom = G["ly"] + G["lh"] * 0.1, G["ly"] + G["lh"]
    y = top
    while y < bottom:
        lines.append([(cx, y), (cx, min(y + g(7), bottom))]); y += g(12)
    # small chevrons either side of the seam: "this opens"
    my = G["ly"] + G["lh"] * 0.55
    for sgn in (-1, 1):
        x = cx + sgn * g(10)
        lines.append([(x, my - g(7)), (x + sgn * g(7), my), (x, my + g(7))])
    m = chalk_lines(lines, width=5, jitter=0.8)
    glow = cv2.GaussianBlur(m, (0, 0), g(4)) * 1.4
    rgb = np.zeros((OUT_H, OUT_W, 3), np.float32) + np.array([255, 250, 245], np.float32)
    return to_rgba(rgb, np.clip(m + glow * 0.5, 0, 1))


def open_bluelake():
    G = window_geometry(); cx, cy = G["cx"], G["cy"]
    half = G["lw"] // 2; top, bottom = G["ly"], G["ly"] + G["lh"]
    am = np.zeros((OUT_H, OUT_W), np.float32)
    am[G["ly"]:G["ly"] + G["lh"], G["lx"]:G["lx"] + G["lw"]] = arch_mask(G["lw"], G["lh"], int(G["lw"] * 0.85))
    deep = np.zeros((OUT_H, OUT_W, 3), np.float32) + np.array([110, 50, 0], np.float32)
    # leaves swung inward, drawn as foreshortened chalk panels; a pedestal far behind
    lw = int(G["lw"] * 0.16)
    lines = [
        [(cx - half, top + G["lh"] * 0.25), (cx - half + lw, top + G["lh"] * 0.3), (cx - half + lw, bottom - g(4)), (cx - half, bottom)],
        [(cx + half, top + G["lh"] * 0.25), (cx + half - lw, top + G["lh"] * 0.3), (cx + half - lw, bottom - g(4)), (cx + half, bottom)],
        [(cx - g(9), bottom - g(4)), (cx - g(9), bottom - g(26)), (cx + g(9), bottom - g(26)), (cx + g(9), bottom - g(4))],
        [(cx - g(14), bottom - g(26)), (cx + g(14), bottom - g(26))],
    ]
    m = chalk_lines(lines, width=3)
    rgb = deep * (1 - m[..., None]) + np.array([250, 245, 240], np.float32) * m[..., None]
    alpha = np.clip(am + m, 0, 1)
    return to_rgba(rgb, alpha)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="art/raw"); ap.add_argument("--out", default="assets/style_sample")
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    plate = build_plate(a.raw)
    cv2.imwrite(os.path.join(a.out, "s05_normal.png"), build_normal(plate))
    handle_normal().save(os.path.join(a.out, "s05_normal_handle.png"))
    open_normal().save(os.path.join(a.out, "s05_normal_open.png"))
    cv2.imwrite(os.path.join(a.out, "s05_bluelake.png"), build_bluelake(plate))
    handle_bluelake().save(os.path.join(a.out, "s05_bluelake_handle.png"))
    open_bluelake().save(os.path.join(a.out, "s05_bluelake_open.png"))
    layout = dict(view=[1152, 648], texture_scale=0.5, window_center=list(WIN_CENTER),
                  window_size=list(WIN_SIZE), wall_base_y=WALL_BASE_Y, floor=[FLOOR_TOP, FLOOR_BOTTOM])
    with open(os.path.join(a.out, "s05_layout.json"), "w") as fh:
        json.dump(layout, fh, indent=2)


if __name__ == "__main__":
    main()

"""Generate the Evimiz app icon in 1024x1024 PNG.

Background: terracotta (#C4593C).
Foreground: stylized 'house with heart' glyph in white.
Output: ../assets/icon.png
"""
from PIL import Image, ImageDraw
from pathlib import Path

SIZE = 1024
BG = (196, 89, 60)        # #C4593C terracotta
FG = (255, 255, 255)
PAD = 0.10                # 10% safe padding


def main() -> None:
    img = Image.new("RGB", (SIZE, SIZE), BG)
    d = ImageDraw.Draw(img)

    pad = int(SIZE * PAD)
    inner = SIZE - 2 * pad

    # --- House outline ---
    # roof apex top-center, roof base sides, walls, floor.
    cx = SIZE // 2
    roof_apex = (cx, pad + int(inner * 0.10))
    roof_left = (pad + int(inner * 0.05), pad + int(inner * 0.45))
    roof_right = (SIZE - pad - int(inner * 0.05), pad + int(inner * 0.45))
    base_left = (pad + int(inner * 0.18), pad + int(inner * 0.45))
    base_right = (SIZE - pad - int(inner * 0.18), pad + int(inner * 0.45))
    floor_left = (pad + int(inner * 0.18), SIZE - pad - int(inner * 0.10))
    floor_right = (SIZE - pad - int(inner * 0.18), SIZE - pad - int(inner * 0.10))

    sw = max(8, SIZE // 32)  # stroke width

    # House polygon (filled white roof outline)
    # Roof: triangle outline
    d.line([roof_apex, roof_left], fill=FG, width=sw, joint="curve")
    d.line([roof_apex, roof_right], fill=FG, width=sw, joint="curve")
    d.line([roof_left, roof_right], fill=FG, width=sw, joint="curve")
    # Walls
    d.line([base_left, floor_left], fill=FG, width=sw, joint="curve")
    d.line([base_right, floor_right], fill=FG, width=sw, joint="curve")
    # Floor
    d.line([floor_left, floor_right], fill=FG, width=sw, joint="curve")

    # --- Heart in the middle ---
    hx = cx
    hy = pad + int(inner * 0.70)
    hw = int(inner * 0.32)
    hh = int(inner * 0.30)
    # Two circles + triangle, all filled white
    r = int(hw * 0.32)
    left_c = (hx - r, hy - int(hh * 0.10))
    right_c = (hx + r, hy - int(hh * 0.10))
    d.ellipse([left_c[0] - r, left_c[1] - r, left_c[0] + r, left_c[1] + r], fill=FG)
    d.ellipse([right_c[0] - r, right_c[1] - r, right_c[0] + r, right_c[1] + r], fill=FG)
    bottom_pt = (hx, hy + int(hh * 0.55))
    d.polygon([
        (hx - hw // 2, hy - int(hh * 0.05)),
        (hx + hw // 2, hy - int(hh * 0.05)),
        bottom_pt,
    ], fill=FG)

    out = Path(__file__).resolve().parent.parent / "assets" / "icon.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, format="PNG")
    print(f"wrote {out}")

    # Generate also a 192 and 512 favicon-class icons for web/icons.
    web_icons_dir = Path(__file__).resolve().parent.parent / "web" / "icons"
    web_icons_dir.mkdir(parents=True, exist_ok=True)
    for size, name in [
        (192, "Icon-192.png"),
        (512, "Icon-512.png"),
        (192, "Icon-maskable-192.png"),
        (512, "Icon-maskable-512.png"),
    ]:
        img.resize((size, size), Image.LANCZOS).save(web_icons_dir / name)
    # favicon
    img.resize((64, 64), Image.LANCZOS).save(Path(__file__).resolve().parent.parent / "web" / "favicon.png")
    print("web icons updated")


if __name__ == "__main__":
    main()

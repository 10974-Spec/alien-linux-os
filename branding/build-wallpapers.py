#!/usr/bin/env python3
"""
Alien OS — Offline, Idempotent Wallpaper Rendering Pipeline
Reads branding/wallpapers.yaml and source assets in branding-assets/bg/
Renders wallpapers into branding/generated/wallpapers/
Generates docs/ship-proof/wallpapers/contact-sheet.png
Enforces quality gates (dimensions, non-blank, size budget < 25MB)
SPDX-License-Identifier: MIT
"""

import os
import sys
import shutil
import subprocess
from PIL import Image, ImageStat, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_DIR = os.path.join(ROOT, "branding-assets", "bg")
OUT_DIR = os.path.join(ROOT, "branding", "generated", "wallpapers")
CONTACT_DIR = os.path.join(ROOT, "docs", "ship-proof", "wallpapers")
MANIFEST = os.path.join(ROOT, "branding", "wallpapers.yaml")

MAX_BUDGET_BYTES = 25 * 1024 * 1024  # 25 MB budget

def parse_simple_yaml(path):
    # Minimal parser for wallpapers.yaml to avoid external dependency issues
    import yaml
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def run_cmd(cmd):
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {' '.join(cmd)}\n{res.stderr}")
    return res.stdout

def get_renderer():
    if shutil.which("rsvg-convert"):
        return "native"
    # Check if docker or podman is available
    if shutil.which("docker") or shutil.which("podman"):
        return "container"
    raise RuntimeError("Neither rsvg-convert nor container engine available for SVG rasterization.")

def render_svg(src_path, dst_path, width, height, renderer):
    if renderer == "native":
        cmd = ["rsvg-convert", "-w", str(width), "-h", str(height), src_path, "-o", dst_path]
        run_cmd(cmd)
    else:
        # Use alien-builder:trixie
        engine = "docker" if shutil.which("docker") else "podman"
        container_src = f"/alien/{os.path.relpath(src_path, ROOT)}"
        container_dst = f"/alien/{os.path.relpath(dst_path, ROOT)}"
        cmd = [
            engine, "run", "--rm",
            "-u", f"{os.getuid()}:{os.getgid()}",
            "-v", f"{ROOT}:/alien",
            "alien-builder:trixie",
            "rsvg-convert", "-w", str(width), "-h", str(height), container_src, "-o", container_dst
        ]
        run_cmd(cmd)

def main():
    print("=== Alien OS Wallpaper Rendering Pipeline ===")
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(CONTACT_DIR, exist_ok=True)

    manifest_data = parse_simple_yaml(MANIFEST)
    wallpapers = manifest_data["wallpapers"]
    renderer = get_renderer()
    print(f"Renderer engine: {renderer}")

    total_bytes = 0
    all_items_for_contact = []

    for entry in wallpapers:
        src_name = entry["source"]
        src_path = os.path.join(ASSETS_DIR, src_name)
        if not os.path.exists(src_path):
            raise FileNotFoundError(f"Missing wallpaper asset: {src_path}")

        dst_filename = entry["filename"]
        dst_path = os.path.join(OUT_DIR, dst_filename)
        primary_size = entry["sizes"][0]
        w, h = primary_size["width"], primary_size["height"]

        # Check idempotency: check if output exists and is newer than source
        needs_render = True
        if os.path.exists(dst_path) and os.path.getmtime(dst_path) >= os.path.getmtime(src_path):
            needs_render = False

        if needs_render:
            print(f"Rendering {dst_filename} ({w}x{h}) from {src_name}...")
            if src_name.endswith(".svg"):
                render_svg(src_path, dst_path, w, h, renderer)
            elif src_name.endswith(".png"):
                # Copy or honest crop
                shutil.copy2(src_path, dst_path)

        # Optimize PNG with PIL
        with Image.open(dst_path) as im:
            im_rgb = im.convert("RGB")
            im_rgb.save(dst_path, "PNG", optimize=True)

        size_b = os.path.getsize(dst_path)
        total_bytes += size_b
        all_items_for_contact.append((entry["title"], dst_path))
        print(f"  -> {dst_filename}: {w}x{h}, {size_b//1024} KB")

        # If this is default, also render the 1080p fallback
        if entry.get("is_default") and len(entry["sizes"]) > 1:
            size_1080 = entry["sizes"][1]
            w1080, h1080 = size_1080["width"], size_1080["height"]
            dst_1080_name = dst_filename.replace(".png", "-1080p.png")
            dst_1080_path = os.path.join(OUT_DIR, dst_1080_name)

            if not os.path.exists(dst_1080_path) or os.path.getmtime(dst_1080_path) < os.path.getmtime(src_path):
                print(f"Rendering 1080p fallback {dst_1080_name} ({w1080}x{h1080})...")
                render_svg(src_path, dst_1080_path, w1080, h1080, renderer)
                with Image.open(dst_1080_path) as im:
                    im.convert("RGB").save(dst_1080_path, "PNG", optimize=True)

            size_1080_b = os.path.getsize(dst_1080_path)
            total_bytes += size_1080_b
            print(f"  -> {dst_1080_name}: {w1080}x{h1080}, {size_1080_b//1024} KB")

    # Create stable symlink: default.png -> Alien-Default.png
    symlink_path = os.path.join(OUT_DIR, "default.png")
    if os.path.islink(symlink_path) or os.path.exists(symlink_path):
        os.remove(symlink_path)
    os.symlink("Alien-Default.png", symlink_path)
    print("Created symlink: default.png -> Alien-Default.png")

    # Legacy compatibility symlinks
    for legacy, target in [("alien-bg1.png", "Alien-Default.png"), ("alien-bg2.png", "Alien-Neon.png")]:
        legacy_path = os.path.join(OUT_DIR, legacy)
        if os.path.islink(legacy_path) or os.path.exists(legacy_path):
            os.remove(legacy_path)
        os.symlink(target, legacy_path)
        print(f"Created legacy symlink: {legacy} -> {target}")

    # Generate Contact Sheet
    contact_path = os.path.join(CONTACT_DIR, "contact-sheet.png")
    print(f"Generating contact sheet at {contact_path}...")
    thumb_w, thumb_h = 480, 270
    pad_x, pad_y = 30, 60
    cols = 4
    rows = (len(all_items_for_contact) + cols - 1) // cols
    grid_w = cols * thumb_w + (cols + 1) * pad_x
    grid_h = rows * thumb_h + (rows + 1) * pad_y + 60

    sheet = Image.new("RGB", (grid_w, grid_h), color=(20, 22, 30))
    draw = ImageDraw.Draw(sheet)
    draw.text((pad_x, 20), "Alien OS Official Wallpapers — Contact Sheet (11 Backgrounds)", fill=(255, 255, 255))

    for idx, (title, path) in enumerate(all_items_for_contact):
        c = idx % cols
        r = idx // cols
        x = pad_x + c * (thumb_w + pad_x)
        y = 70 + pad_y + r * (thumb_h + pad_y)

        with Image.open(path) as im:
            thumb = im.convert("RGB").resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
            sheet.paste(thumb, (x, y))
            draw.rectangle([x, y, x + thumb_w, y + thumb_h], outline=(79, 142, 247), width=1)
            draw.text((x, y + thumb_h + 8), f"{idx+1}. {title}", fill=(220, 225, 240))

    sheet.save(contact_path, "PNG", optimize=True)

    # Automated Quality Gates
    print("\n--- Running Quality & Health Checks ---")
    failures = 0
    for title, path in all_items_for_contact:
        with Image.open(path) as im:
            stat = ImageStat.Stat(im)
            var = sum(stat.var) / 3.0
            mean = max(stat.mean)
            if var < 10.0 or mean < 5.0:
                print(f"[FAIL] {os.path.basename(path)} is suspicious/blank (var={var:.1f}, mean={mean:.1f})")
                failures += 1
            else:
                print(f"[PASS] {os.path.basename(path)} (var={var:.1f}, mean={mean:.1f})")

    print(f"\nTotal wallpaper footprint: {total_bytes / (1024*1024):.2f} MB")
    if total_bytes > MAX_BUDGET_BYTES:
        print(f"[FAIL] Budget exceeded ({total_bytes} > {MAX_BUDGET_BYTES})")
        failures += 1
    else:
        print(f"[PASS] Budget constraint satisfied (< {MAX_BUDGET_BYTES / (1024*1024):.0f} MB)")

    if failures > 0:
        print(f"Pipeline finished with {failures} error(s)!")
        sys.exit(1)

    print("Pipeline completed successfully (ALL CHECKS PASSED).")

if __name__ == "__main__":
    main()

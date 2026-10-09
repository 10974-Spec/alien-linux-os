# Alien OS Branding Guide

Alien OS uses a centralized, single-source-of-truth branding engine to customize the visual identity of both the Full and Lite editions.

This guide explains how to respin the distribution with your own custom logo, wallpapers, fonts, and colors.

## 1. The Branding Hub (`branding/tokens.env`)

All branding values across the entire OS are defined in one place:
**`branding/tokens.env`**

This file controls the global configuration:
```env
OS_NAME="Alien"
COLOR_ACCENT="#4f8ef7"
COLOR_DARK_SHADE="#1a1b26"
COLOR_LIGHT_NEUTRAL="#ffffff"
COLOR_SUCCESS="#9ece6a"
FONT_UI="DejaVu Sans"
FONT_MONO="DejaVu Sans Mono"
BORDER_RADIUS="8"
```

If you wish to change the OS name, simply edit `OS_NAME`. To change the overall color scheme, adjust the HEX codes here. The `COLOR_ACCENT` variable determines the button colors, highlight text, and Plasma theme accents.

## 2. Branding Assets (`branding-assets/`)

To replace the visual elements (Logos and Backgrounds), replace the master files located in the `branding-assets/` directory.

### Logos
- **`logo-main.svg`**: This is the primary icon used for the Plymouth boot splash, the login screen (SDDM/LightDM) avatar, Calamares installer, and the About page.
- **`logo-bar.svg`**: This is used exclusively as the launcher (Home button) icon on the desktop shelf.

### Backgrounds
- **`bg1.svg`**: The primary background for the OS. It is automatically blurred for the Plymouth boot splash and the Login/Lock screens, and used as the default desktop wallpaper.
- **`bg2.png`**: An alternate background made available in the desktop's wallpaper picker.

*Note: Ensure your vectors are standard SVGs, or supply high-resolution PNGs with the same names.*

## 3. Regenerating Assets

After replacing the logos and editing the `tokens.env` variables, you must generate the derivative files that the build scripts expect.

Run the asset generation script from the project root:
```bash
./branding/generate.sh
```

This script will automatically:
1. Parse the SVGs and rasterize them into various pixel densities.
2. Extract your `COLOR_ACCENT` and apply it where necessary.
3. Apply strong Gaussian blurs (`0x15` and `0x35`) to `bg1.svg` to create the login and boot splash backgrounds.
4. Scale icons for `/usr/share/icons/hicolor/` sizes (16x16 up to 512x512).

## 4. Rebuilding the OS

Once the new assets are generated and `tokens.env` is configured, you are ready to build the new ISOs.

Run the main build script:
```bash
./build/build.sh full
./build/build.sh lite
```

The system assembly scripts automatically read `tokens.env` and the generated PNGs to theme GRUB, Plymouth, SDDM, LightDM, the KDE Plasma look-and-feel, terminal prompts, and Calamares.

Enjoy your custom respin!

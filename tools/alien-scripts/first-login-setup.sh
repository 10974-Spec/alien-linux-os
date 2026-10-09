#!/usr/bin/env bash
# Alien — first login setup script
# This applies the Alien global theme and defaults without any clicking.

# Apply the Look-and-Feel theme
lookandfeeltool -a org.alien.desktop

# Set window decoration to breeze with small titlebars
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize Normal

# Force the layout to reset to our custom panel
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
  var panels = panels();
  for (var i = 0; i < panels.length; ++i) {
    panels[i].remove();
  }
  loadTemplate('org.alien.desktop.layout');
"

# Set wallpaper
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
  var allDesktops = desktops();
  for (i=0;i<allDesktops.length;i++) {
      d = allDesktops[i];
      d.wallpaperPlugin = 'org.kde.image';
      d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
      d.writeConfig('Image', 'file:///usr/share/backgrounds/alien-bg1.png');
  }
"
echo "Alien: First login setup complete."
# Disable this script from running again
rm -f "$0"

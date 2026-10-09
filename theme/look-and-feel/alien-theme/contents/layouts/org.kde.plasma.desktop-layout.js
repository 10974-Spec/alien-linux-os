var panel = new Panel
panel.location = "bottom"
panel.height = 48
panel.alignment = "center"
panel.lengthMode = "fit"
panel.floating = true
panel.hiding = "windowscover"

// Left: Launcher
panel.addWidget("org.kde.plasma.kickoff")

// Center: Icons only task manager
var icontasks = panel.addWidget("org.kde.plasma.icontasks")
icontasks.currentConfigGroup = ["General"]
// We define the pinned apps here
icontasks.writeConfig("launchers", [
    "applications:brave-browser.desktop",
    "applications:org.telegram.desktop.desktop",
    "applications:org.kde.elisa.desktop",
    "applications:io.mpv.Mpv.desktop",
    "applications:info.febvre.Komikku.desktop",
    "applications:io.encroissant.EnCroissant.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.discover.desktop"
])

// Right: System Tray and Clock
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")

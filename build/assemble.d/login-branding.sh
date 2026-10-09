#!/usr/bin/env bash
# Alien — Login Screen Branding (Phase 4)
set -euo pipefail

DEST_SDDM="$WORK/config/includes.chroot/usr/share/sddm/themes/alien"
mkdir -p "$DEST_SDDM"

# SDDM Theme
cat > "$DEST_SDDM/metadata.desktop" <<EOF
[SddmGreeterTheme]
Name=Alien
Description=Alien OS Login Theme
Author=Alien Project
Theme-Id=alien
Version=0.1
Type=sddm-theme
EOF

cat > "$DEST_SDDM/theme.conf" <<EOF
[General]
background=bg-login.png
type=image
logo=logo-main.png
EOF

cat > "$DEST_SDDM/Main.qml" <<'EOF'
import QtQuick 2.8
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import SddmComponents 2.0

Rectangle {
    width: 1920
    height: 1080
    
    Image {
        id: background
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
    }
    
    // Top Right Clock
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        color: "white"
        font.pointSize: 24
        font.family: "DejaVu Sans"
        text: Qt.formatDateTime(new Date(), "hh:mm")
        
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm")
        }
    }
    
    // Centered Login Card
    Rectangle {
        width: 350
        height: 450
        anchors.centerIn: parent
        color: "#AA1A1B26"
        radius: 8
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            
            Image {
                source: config.logo
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
            }
            
            TextField {
                id: userField
                Layout.preferredWidth: 250
                placeholderText: "Username"
                text: "alien"
                font.family: "DejaVu Sans"
                horizontalAlignment: TextInput.AlignHCenter
                background: Rectangle {
                    color: "#33FFFFFF"
                    radius: 4
                }
                color: "white"
            }
            
            TextField {
                id: passField
                Layout.preferredWidth: 250
                placeholderText: "Password"
                echoMode: TextInput.Password
                font.family: "DejaVu Sans"
                horizontalAlignment: TextInput.AlignHCenter
                background: Rectangle {
                    color: "#33FFFFFF"
                    radius: 4
                }
                color: "white"
                onAccepted: sddm.login(userField.text, passField.text, session.index)
            }
            
            Button {
                text: "Login"
                Layout.preferredWidth: 250
                font.family: "DejaVu Sans"
                background: Rectangle {
                    color: "@ALIEN_ACCENT@"
                    radius: 4
                }
                onClicked: sddm.login(userField.text, passField.text, session.index)
            }
        }
    }
    
    // Bottom Controls
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        spacing: 10
        
        ComboBox {
            id: session
            model: sessionModel
            textRole: "name"
            font.family: "DejaVu Sans"
            visible: false
        }
        
        Button {
            text: "Reboot"
            font.family: "DejaVu Sans"
            onClicked: sddm.reboot()
        }
        Button {
            text: "Shutdown"
            font.family: "DejaVu Sans"
            onClicked: sddm.powerOff()
        }
    }
}
EOF

# Copy SDDM assets
cp "$SRC/branding/generated/backgrounds/bg-login.png" "$DEST_SDDM/"
cp "$SRC/branding/generated/logos/logo-main-256.png" "$DEST_SDDM/logo-main.png"

# Set SDDM default theme
mkdir -p "$WORK/config/includes.chroot/etc/sddm.conf.d"
cat > "$WORK/config/includes.chroot/etc/sddm.conf.d/alien.conf" <<EOF
[Theme]
Current=alien

[General]
InputMethod=
EOF

# LightDM Theme
DEST_LIGHTDM="$WORK/config/includes.chroot/etc/lightdm"
mkdir -p "$DEST_LIGHTDM"
cat > "$DEST_LIGHTDM/lightdm-gtk-greeter.conf" <<EOF
[greeter]
background = /usr/share/backgrounds/alien-login.png
theme-name = Adwaita-dark
font-name = DejaVu Sans 10
icon-theme-name = Papirus
default-user-image = /usr/share/icons/hicolor/128x128/apps/alien-launcher.png
position = 50%,center 50%,center
hide-user-image = false
indicators = ~clock;~power
clock-format = %H:%M
EOF

# Copy LightDM background
mkdir -p "$WORK/config/includes.chroot/usr/share/backgrounds"
cp "$SRC/branding/generated/backgrounds/bg-login.png" "$WORK/config/includes.chroot/usr/share/backgrounds/alien-login.png"

echo "  - Configured SDDM and LightDM branding"

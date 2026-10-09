#!/usr/bin/env bats

setup() {
    export XDG_CONFIG_HOME="$BATS_TMPDIR/config"
    mkdir -p "$XDG_CONFIG_HOME/lxqt"
    cat > "$XDG_CONFIG_HOME/lxqt/panel.conf" <<EOF
[quicklaunch]
alignment=Left
apps\1\desktop=/usr/share/applications/pcmanfm-qt.desktop
apps\size=1
type=quicklaunch
EOF
    export PATH="$BATS_TEST_DIRNAME/../tools/alien-pin:$PATH"
    
    # Create fake desktop file for testing
    mkdir -p "$BATS_TMPDIR/usr/share/applications"
    touch "$BATS_TMPDIR/usr/share/applications/fake.desktop"
}

teardown() {
    rm -rf "$BATS_TMPDIR/config"
    rm -rf "$BATS_TMPDIR/usr"
}

@test "alien-pin adds an app to panel" {
    run alien-pin "$BATS_TMPDIR/usr/share/applications/fake.desktop"
    [ "$status" -eq 0 ]
    run grep -q "desktop=$BATS_TMPDIR/usr/share/applications/fake.desktop" "$XDG_CONFIG_HOME/lxqt/panel.conf"
    [ "$status" -eq 0 ]
    run grep -q "apps\\\\size=2" "$XDG_CONFIG_HOME/lxqt/panel.conf"
    [ "$status" -eq 0 ]
}

@test "alien-pin removes an app from panel" {
    alien-pin "$BATS_TMPDIR/usr/share/applications/fake.desktop"
    run alien-pin "$BATS_TMPDIR/usr/share/applications/fake.desktop"
    [ "$status" -eq 0 ]
    run grep -q "desktop=$BATS_TMPDIR/usr/share/applications/fake.desktop" "$XDG_CONFIG_HOME/lxqt/panel.conf"
    [ "$status" -eq 1 ]
}

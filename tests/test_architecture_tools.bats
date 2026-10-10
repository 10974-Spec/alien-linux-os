#!/usr/bin/env bats
# Tests for Alien Architecture Tools (Prompt 2)

setup() {
	export TOOLS_DIR="$BATS_TEST_DIRNAME/../tools"
}

@test "alien-snapshot --help and --dry-run create" {
	run "$TOOLS_DIR/alien-snapshot/alien-snapshot" --help
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Usage: alien-snapshot" ]]

	run "$TOOLS_DIR/alien-snapshot/alien-snapshot" --dry-run create "Test Backup"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "[DRY-RUN] Would create snapshot with description: 'Test Backup'" ]]
}

@test "alien-protect status runs and reports state" {
	run "$TOOLS_DIR/alien-protect/alien-protect" status
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Alien OS Protected Mode Status" ]]
}

@test "alien-pkg suggest recommends correct tiers" {
	run "$TOOLS_DIR/alien-pkg/alien-pkg" suggest rust
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Recommended Tier: --sandbox" ]]

	run "$TOOLS_DIR/alien-pkg/alien-pkg" suggest linux-image
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Recommended Tier: --system" ]]

	run "$TOOLS_DIR/alien-pkg/alien-pkg" suggest spotify
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Recommended Tier: --flatpak" ]]
}

@test "alien-doctor runs diagnostics" {
	run "$TOOLS_DIR/alien-doctor/alien-doctor"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Alien OS Doctor Health Diagnostic" ]]
	[[ "$output" =~ "Results:" ]]
}

@test "alien-audio-profile status runs cleanly" {
	run "$TOOLS_DIR/alien-audio-profile/alien-audio-profile" status
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Alien OS Audio Status" ]]
}

@test "alien-gpu-check runs diagnostics" {
	run "$TOOLS_DIR/alien-gpu-check/alien-gpu-check"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Alien OS GPU & Hardware Acceleration Report" ]]
}

#!/usr/bin/env bats
# Tests for alien-tune against fake /sys and configuration trees

setup() {
	export TUNE_BIN="$BATS_TEST_DIRNAME/../tools/alien-tune/alien-tune"
	export TEST_TMP="$BATS_TMPDIR/alien-tune-test"
	mkdir -p "$TEST_TMP/sys/block/nvme0n1/queue"
	mkdir -p "$TEST_TMP/sys/block/sda/queue"
	mkdir -p "$TEST_TMP/sys/block/sdb/queue"
	mkdir -p "$TEST_TMP/sys/class/power_supply/BAT0"
	mkdir -p "$TEST_TMP/conf.d"

	# Fake NVMe
	echo "[none] mq-deadline" > "$TEST_TMP/sys/block/nvme0n1/queue/scheduler"
	echo "0" > "$TEST_TMP/sys/block/nvme0n1/queue/rotational"

	# Fake Rotational HDD (sda)
	echo "[mq-deadline] bfq none" > "$TEST_TMP/sys/block/sda/queue/scheduler"
	echo "1" > "$TEST_TMP/sys/block/sda/queue/rotational"

	# Fake Non-rotational SSD (sdb)
	echo "[none] mq-deadline bfq" > "$TEST_TMP/sys/block/sdb/queue/scheduler"
	echo "0" > "$TEST_TMP/sys/block/sdb/queue/rotational"

	# Fake battery
	echo "Battery" > "$TEST_TMP/sys/class/power_supply/BAT0/type"

	# Fake profile
	echo "vm.dirty_ratio=10" > "$TEST_TMP/conf.d/custom.conf"

	export ALIEN_SYS_DIR="$TEST_TMP/sys"
	export ALIEN_CONF_DIR="$TEST_TMP/conf.d"
	export ALIEN_TUNE_DRY_RUN=1
}

teardown() {
	rm -rf "$TEST_TMP"
}

@test "alien-tune detects NVMe and targets none scheduler" {
	run "$TUNE_BIN"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Device nvme0n1: target scheduler none" ]]
}

@test "alien-tune detects rotational disk and targets bfq scheduler" {
	run "$TUNE_BIN"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Device sda: target scheduler bfq" ]]
}

@test "alien-tune detects non-rotational SSD and targets mq-deadline scheduler" {
	run "$TUNE_BIN"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Device sdb: target scheduler mq-deadline" ]]
}

@test "alien-tune detects laptop hardware when battery exists" {
	run "$TUNE_BIN"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Laptop hardware detected" ]]
}

@test "alien-tune applies custom profile settings" {
	run "$TUNE_BIN"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Applying profile:" ]]
	[[ "$output" =~ "vm.dirty_ratio = 10" ]]
}

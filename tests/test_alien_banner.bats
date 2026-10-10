#!/usr/bin/env bats
# Tests for alien-banner CLI command

setup() {
    export BANNER_BIN="$BATS_TEST_DIRNAME/../tools/alien-banner/alien-banner"
    export TEST_TMP="$BATS_TMPDIR/alien-banner-test"
    mkdir -p "$TEST_TMP"
    export HOME="$TEST_TMP"
    unset ALIEN_NO_BANNER
    unset NO_COLOR
    unset ALIEN_BANNER_STYLE
    unset COLUMNS
    unset LINES
}

teardown() {
    rm -rf "$TEST_TMP"
}

@test "alien-banner --text outputs plain text with tagline" {
    run "$BANNER_BIN" --text
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Your world, your way." ]]
    [[ "$output" =~ "Kernel:" ]]
    [[ "$output" =~ "Memory:" ]]
}

@test "alien-banner with NO_COLOR=1 produces plain text without ANSI colors" {
    run env NO_COLOR=1 "$BANNER_BIN"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Your world, your way." ]]
    # Should not contain color escape sequence \033[3
    [[ ! "$output" =~ $(printf '\033[3') ]]
}

@test "alien-banner with ALIEN_NO_BANNER=1 produces zero output" {
    run env ALIEN_NO_BANNER=1 "$BANNER_BIN"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "alien-banner with ~/.config/alien/no-banner file produces zero output" {
    mkdir -p "$HOME/.config/alien"
    touch "$HOME/.config/alien/no-banner"
    run "$BANNER_BIN"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "alien-banner --compact runs and outputs compact art" {
    run "$BANNER_BIN" --compact
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Your world, your way." ]]
    [[ "$output" =~ "Kernel:" ]]
}

@test "alien-banner auto-switches to compact in narrow terminal (COLUMNS=65)" {
    run env COLUMNS=65 LINES=24 "$BANNER_BIN"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Your world, your way." ]]
}


@test "alien-banner runs in under 30 ms" {
    start_time=$(date +%s%N)
    "$BANNER_BIN" >/dev/null 2>&1
    end_time=$(date +%s%N)
    # Difference in nanoseconds to ms
    diff_ns=$((end_time - start_time))
    diff_ms=$((diff_ns / 1000000))
    echo "Run time: ${diff_ms} ms"
    [ "$diff_ms" -lt 30 ]
}

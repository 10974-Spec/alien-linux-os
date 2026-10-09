#!/usr/bin/env bash
# Alien — checks that this computer is ready to build and test Alien.
# Usage:  ./scripts/check-environment.sh
# Prints PASS / WARN / FAIL for each item. Changes nothing on your system.

cd "$(dirname "$0")/.." || exit 1
fails=0; warns=0
pass() { printf '  \e[32mPASS\e[0m  %s\n' "$1"; }
warn() { printf '  \e[33mWARN\e[0m  %s\n' "$1"; warns=$((warns+1)); }
fail() { printf '  \e[31mFAIL\e[0m  %s\n' "$1"; fails=$((fails+1)); }

echo "Alien build environment check"
echo "-----------------------------"

# CPU
[ "$(uname -m)" = "x86_64" ] && pass "64-bit x86 CPU" || fail "CPU is not x86_64"
grep -Eq '(vmx|svm)' /proc/cpuinfo && pass "CPU virtualization (VT-x/AMD-V)" \
  || fail "CPU virtualization off — enable VT-x/AMD-V in BIOS"
cores=$(nproc)
[ "$cores" -ge 4 ] && pass "$cores CPU cores" || warn "Only $cores CPU cores (builds will be slow)"

# Memory
ram_gb=$(awk '/MemTotal/{printf "%d", $2/1024/1024+0.5}' /proc/meminfo)
[ "$ram_gb" -ge 8 ] && pass "${ram_gb} GB RAM" || warn "${ram_gb} GB RAM (8 GB+ recommended; VM uses 4 GB)"

# Disk
free_gb=$(df -BG --output=avail . | tail -1 | tr -dc '0-9')
[ "$free_gb" -ge 40 ] && pass "${free_gb} GB free disk" || fail "Only ${free_gb} GB free (need 40 GB)"

# Container engine
if command -v podman >/dev/null; then
  pass "Podman installed (builds will use: sudo podman)"
elif command -v docker >/dev/null; then
  if docker info >/dev/null 2>&1; then pass "Docker installed and usable without sudo"
  else fail "Docker installed but not usable — run: sudo usermod -aG docker \$USER, then log out/in"; fi
else
  fail "No container engine — install with: sudo apt install podman"
fi

# QEMU / KVM
command -v qemu-system-x86_64 >/dev/null && pass "QEMU (qemu-system-x86_64)" \
  || fail "QEMU missing — install with: sudo apt install qemu-system-x86 qemu-utils ovmf"
command -v qemu-img >/dev/null && pass "qemu-img" || fail "qemu-img missing (package qemu-utils)"
[ -r /dev/kvm ] && [ -w /dev/kvm ] && pass "KVM acceleration (/dev/kvm)" \
  || fail "/dev/kvm not accessible — run: sudo usermod -aG kvm \$USER, then log out/in"
if ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | grep -q .; then
  pass "UEFI firmware for VMs (OVMF)"
else
  fail "OVMF missing — install with: sudo apt install ovmf"
fi

# Misc
command -v git >/dev/null && pass "git" || warn "git missing (optional) — sudo apt install git"
if curl -fsS -m 10 -o /dev/null http://deb.debian.org/debian/dists/trixie/Release; then
  pass "Internet access to Debian mirror"
else
  fail "Cannot reach deb.debian.org (builds need internet)"
fi

echo "-----------------------------"
if [ "$fails" -eq 0 ]; then
  echo "RESULT: PASS ($warns warning(s)) — you are ready to build."
else
  echo "RESULT: FAIL ($fails problem(s), $warns warning(s)) — fix the FAIL lines above."
fi
exit "$fails"

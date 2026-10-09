.PHONY: all check iso-lite iso-full test-qemu clean

all: iso-lite

check:
	@echo "Running lint checks..."
	ci/run-local.sh

iso-lite:
	@echo "Building Alien Lite ISO..."
	./build/build.sh lite

iso-full:
	@echo "Building Alien Full ISO..."
	./build/build.sh full

test-qemu:
	@echo "Running QEMU smoke tests..."
	./tests/test-in-qemu.sh out/alien-lite-0.1-20261008-amd64.iso

clean:
	@echo "Cleaning out/"
	rm -rf out/*.iso out/*.sha256 out/build.log

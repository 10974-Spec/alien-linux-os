.PHONY: all check iso-lite iso-full gate-lite gate-full test-qemu clean clean-iso

all: iso-lite

check:
	@echo "Running lint checks..."
	ci/run-local.sh

clean-iso:
	@echo "Cleaning live-build caches and build state..."
	docker volume rm -f alien-build-cache 2>/dev/null || true
	rm -rf out/.build out/chroot out/cache 2>/dev/null || true

gate-lite:
	@echo "Running automated ship gate on newest Lite ISO..."
	python3 tests/qemu-gate.py

gate-full:
	@echo "Running automated ship gate on newest Full ISO..."
	python3 tests/qemu-gate.py

iso-lite:
	@echo "Building Alien Lite ISO..."
	./build/build.sh lite
	@echo "Running verification gate..."
	$(MAKE) gate-lite

iso-full:
	@echo "Building Alien Full ISO..."
	./build/build.sh full
	@echo "Running verification gate..."
	$(MAKE) gate-full

test-qemu:
	@echo "Running QEMU smoke tests..."
	./tests/test-in-qemu.sh $$(ls -t out/*.iso | head -1)

clean:
	@echo "Cleaning out/"
	rm -rf out/*.iso out/*.sha256 out/build.log


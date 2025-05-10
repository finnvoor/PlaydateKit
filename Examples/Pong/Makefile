.PHONY: build
build: build_simulator
	
.PHONY: build_simulator
build_simulator:
	swift build --toolset toolset_simulator.json

.PHONY: clean
clean:
	swift package clean
	rm -rf .build

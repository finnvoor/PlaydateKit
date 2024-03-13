REPO_ROOT := $(shell git rev-parse --show-toplevel)
PRODUCT := build/Life.pdx
SRC += $(REPO_ROOT)/Sources/CPlaydate/playdate.c
include $(REPO_ROOT)/Examples/swift.mk

# MARK: - Build Playdate Overlay Swift Module
build/Modules/playdate_device.o: $(REPO_ROOT)/Sources/PlaydateKit/*.swift
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_DEVICE) -c $^ -emit-module -o $@

build/Modules/playdate_simulator.o: $(REPO_ROOT)/Sources/PlaydateKit/*.swift
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_SIMULATOR) -c $^ -emit-module -o $@

# MARK: - Build Game Swift Object
build/game_device.o: Sources/Life/*.swift | build/Modules/playdate_device.o
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_DEVICE) -c $^ -o $@
$(OBJDIR)/pdex.elf: build/game_device.o
OBJS += build/game_device.o

build/game_simulator.o: Sources/Life/*.swift | build/Modules/playdate_simulator.o
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_SIMULATOR) -c $^ -o $@
$(OBJDIR)/pdex.${DYLIB_EXT}: build/game_simulator.o
SIMCOMPILER += build/game_simulator.o

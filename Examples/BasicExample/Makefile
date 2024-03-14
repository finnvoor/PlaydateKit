REPO_ROOT := $(shell git rev-parse --show-toplevel)
PRODUCT := build/BasicExample.pdx
SRC += $(REPO_ROOT)/Sources/CPlaydate/playdate.c
include $(REPO_ROOT)/Examples/swift.mk

# MARK: - Build PlaydateKit Swift Module
build/Modules/playdatekit_device.o: $(REPO_ROOT)/Sources/PlaydateKit/*.swift
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_DEVICE) -c $^ -emit-module -o $@

build/Modules/playdatekit_simulator.o: $(REPO_ROOT)/Sources/PlaydateKit/*.swift
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_SIMULATOR) -c $^ -emit-module -o $@

# MARK: - Build BasicExample Swift Object
build/basicexample_device.o: Sources/BasicExample/*.swift | build/Modules/playdatekit_device.o
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_DEVICE) -c $^ -o $@
$(OBJDIR)/pdex.elf: build/basicexample_device.o
OBJS += build/basicexample_device.o

build/basicexample_simulator.o: Sources/BasicExample/*.swift | build/Modules/playdatekit_simulator.o
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_SIMULATOR) -c $^ -o $@
$(OBJDIR)/pdex.${DYLIB_EXT}: build/basicexample_simulator.o
SIMCOMPILER += build/basicexample_simulator.o

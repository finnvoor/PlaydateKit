# Declares where PlaydateKit is stored. In this example, PDKIT_ROOT is the
# same as REPO_ROOT. In some setups and projects, this may differ.
PDKIT_ROOT := $(shell git rev-parse --show-toplevel)

# Declares information about the product being build. PRODUCT_NAME will
# likely be the name of the Swift package or game where the source code
# lives. PRODUCT points to where the build Playdate package file (pdx)
# will be stored.
PRODUCT_NAME := BasicExample
PRODUCT := build/$(PRODUCT_NAME).pdx

include $(PDKIT_ROOT)/Examples/swift.mk

# This is used to echo out the product path based on PRODUCT_NAME.
product_path:
	echo $(PRODUCT)
	
.PHONY: product_path

# MARK: - Build PlaydateKit Swift Module
build/Modules/playdatekit_device.o: $(PDKIT_ROOT)/Sources/PlaydateKit/*.swift
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_DEVICE) -c $^ -emit-module -o $@

build/Modules/playdatekit_simulator.o: $(PDKIT_ROOT)/Sources/PlaydateKit/*.swift
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_SIMULATOR) -c $^ -emit-module -o $@

# MARK: - Build Game Swift Object
build/$(PRODUCT_NAME)_device.o: Sources/$(PRODUCT_NAME)/*.swift | build/Modules/playdatekit_device.o
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_DEVICE) -c $^ -o $@
$(OBJDIR)/pdex.elf: build/$(PRODUCT_NAME)_device.o
OBJS += build/$(PRODUCT_NAME)_device.o

build/$(PRODUCT_NAME)_simulator.o: Sources/$(PRODUCT_NAME)/*.swift | build/Modules/playdatekit_simulator.o
	$(SWIFT_EXEC) $(SWIFT_FLAGS) $(SWIFT_FLAGS_SIMULATOR) -c $^ -o $@
$(OBJDIR)/pdex.${DYLIB_EXT}: build/$(PRODUCT_NAME)_simulator.o
SIMCOMPILER += build/$(PRODUCT_NAME)_simulator.o

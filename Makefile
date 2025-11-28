include build_scripts/config.mk

.PHONY: all disk_image bootloader run always clean

all: disk_image

include build_scripts/toolchain.mk

#
# Disk image
#
disk_image: $(BUILD_DIR)/disk_image.raw

$(BUILD_DIR)/disk_image.raw: bootloader
	@./build_scripts/make_disk.sh $@ $(MAKE_DISK_SIZE)
	@echo "--> Created: " $@

#
# Bootloader
#
bootloader: stage1 stage2

#
# Stage1
#
stage1: always
	@$(MAKE) -C $(PROJECT_DIR)/src/bootloader/stage1

#
# Stage2
#
stage2: always
	@$(MAKE) -C $(PROJECT_DIR)/src/bootloader/stage2

#
# Run
#
run:
	@./run.sh

#
# Always
#
always:
	@mkdir -p $(BUILD_DIR)

#
# Always
#
clean:
	@rm -rf $(BUILD_DIR)/**
include build_scripts/config.mk

.PHONY: all floppy_image bootloader run always clean

all: floppy_image

include build_scripts/toolchain.mk

#
# Floppy image
#
floppy_image: $(BUILD_DIR)/floppy_image.img

$(BUILD_DIR)/floppy_image.img: bootloader
	@cp $(BUILD_DIR)/stage1.bin $@
	@truncate -s 1440k $@

#
# Bootloader
#
bootloader: stage1

#
# Stage1
#
stage1: always
	@$(MAKE) -C $(PROJECT_DIR)/src/bootloader/stage1

#
# Run
#
run: $(BUILD_DIR)/floppy_image.img
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
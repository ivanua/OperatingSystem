ASMFLAGS += -f bin

.PHONY: all

all: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: boot.asm
	@$(ASM) $(ASMFLAGS) -o $@ $<
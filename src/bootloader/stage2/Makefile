ASMFLAGS += -f bin

.PHONY: all

all: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: entry.asm
	@$(ASM) $(ASMFLAGS) -o $@ $<
	@echo "--> Created  stage2.bin"
export TARGET ?= basys3

export TOP_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
export TARGET_DIR = $(TOP_DIR)/targets/$(TARGET)
export BUILD_DIR = $(TOP_DIR)/builds/$(TARGET)

.PHONY: all clean

all:
	$(MAKE) -f $(TARGET_DIR)/Makefile.project target-project

clean:
	$(MAKE) -f $(TARGET_DIR)/Makefile.project target-clean
	$(RM) -rf $(BUILD_DIR)


TRANSLATION_DIR=Briefcase-$(shell date +%Y-%m-%d)
TRANSLATION_PATH=$(TARGET_BUILD_DIR)/$(TRANSLATION_DIR)


xib_files := $(notdir $(wildcard $(SRCROOT)/English.lproj/*.xib))
strings_files := $(patsubst %.xib,%.strings,$(xib_files))
source_files := $(wildcard $(SRCROOT)/Classes/*.m)

VPATH = $(TRANSLATION_PATH):$(SRCROOT)/English.lproj:$(SRCROOT)/Classes

all: 
	mkdir -p $(TRANSLATION_PATH)
	./extract_translations.py --project $(SRCROOT) --output $(TRANSLATION_PATH) --source $(SRCROOT)/Classes
	

	


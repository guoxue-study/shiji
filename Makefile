TOP_DIR=.
SRC_DIR=$(TOP_DIR)/slides
TARGET_DIR=$(TOP_DIR)/_build
ASSET_DIR=$(TOP_DIR)/assets
TOOL_DIR=$(TOP_DIR)/tools
CLI_DIR=$(TOOL_DIR)/cli

ENGINE=$(CLI_DIR)/engine.js

MARP=marp --engine $(ENGINE) --theme $(ASSET_DIR)/custom.css --html true

init: install dep
	@echo "Initializing the repo..."

travis-init: install dep
	@echo "Initialize software required for travis (normally ubuntu software)"

install:
	@echo "Install software required for this repo..."
	@npm install -g @marp-team/marp-cli

dep:
	@echo "Install dependencies required for this repo..."
	@npm install

travis: build

travis-deploy: release
	@echo "Deploy the software by travis"

run:
	@$(MARP) -s $(SRC_DIR)

build: $(TARGET_DIR) copy-assets
	@$(MARP) -I slides -o _build

build-pdf: build
	@$(MARP) -I slides -o _build --allow-local-files --pdf

copy-assets:
	@rsync -arv $(SRC_DIR)/assets $(TARGET_DIR)

gen-audios: # must pass CHAPTER=xxx
	@tools/cli/tts.js -i resources/_meta/$(CHAPTER).json

gen-slides:
	@tools/cli/generator.js -i resources/_meta -o slides

gen-meta:
	@tools/cli/normalizer.js -i resources/_src -o resources/_meta

gen-src:
	@cd resources; csplit -f '' -n 3 -k all.txt '/^#/' '{300}' || true; rename [0-9]* -a ".md"; mv *.md _src

$(TARGET_DIR):
	@mkdir -p $@

merge-audio: # need to define CHAPTER, N1 and N2, e.g. N1=23 N2=24, result will be 23_24.mp3
	@cd slides/assets/audios/$(CHAPTER) && ffmpeg -i "concat:$(N1).mp3|$(N2).mp3" -acodec copy $(N1)_$(N2).mp3

split-audio: # need to define CHAPTER, N, SPLIT_AT, e.g. N=139, result will be 139_1.mp3, 139_2.mp3
	@cd slides/assets/audios/$(CHAPTER) && ffmpeg -i ${N}.mp3 -acodec copy -ss 0 -to ${SPLIT_AT} ${N}_1.mp3 && ffmpeg -i ${N}.mp3 -acodec copy -ss ${SPLIT_AT} ${N}_2.mp3


include .makefiles/*.mk

.PHONY: build init travis-init install dep travis clean run build build-pdf travis-deploy release create-pr bump-version

PICO8   ?= $(HOME)/Code/pico-8/PICO-8.app/Contents/MacOS/pico8
CART    := cart.p8

# override per-invocation, e.g. `make build AUTHOR=mauro_vb`, or just edit
# these defaults once per project
PROJECT_NAME ?= $(notdir $(CURDIR))
AUTHOR       ?= $(shell git config user.name 2>/dev/null)

.PHONY: build run test flat new spritedit

# regenerate cart.p8's #include list (and title/author header) from src/ and data/
build:
	python3 build.py --name "$(PROJECT_NAME)" --author "$(AUTHOR)"

# rebuild, then launch in pico8
run: build
	$(PICO8) $(CART)

# run tests/test_*.lua headless against the game code; fails on FAIL or
# runtime error. snap("name") calls in tests end up in tests/snaps/name.png
test:
	python3 build.py --test --name "$(PROJECT_NAME)" --author "$(AUTHOR)"
	@$(PICO8) -x tests/run.p8 > tests/.last_run.log 2>&1; grep -v "^snap " tests/.last_run.log
	@python3 tests/snap.py
	@! grep -v "^snap " tests/.last_run.log | grep -qiE "fail|error"

# single-file, comment-free build/<name>.p8 -- use this one to export
# (.p8.png / html / binaries) or upload, since comments count toward the
# compressed code limit
flat:
	python3 build.py --flat --name "$(PROJECT_NAME)" --author "$(AUTHOR)"

# standalone sprite-region editor -- edits/exports data/myspr.txt, previewing
# sprites live from cart.p8's spritesheet (see spritedit_tool.p8's header)
spritedit:
	$(PICO8) spritedit_tool.p8

# scaffold a sibling project from this template: make new NAME=my_game
new:
ifndef NAME
	$(error usage: make new NAME=my_game)
endif
	mkdir -p ../$(NAME)
	cp -R . ../$(NAME)
	rm -rf ../$(NAME)/.git ../$(NAME)/__pycache__ ../$(NAME)/build \
		../$(NAME)/tests/snaps ../$(NAME)/tests/run.p8 ../$(NAME)/tests/.last_run.log
	@echo "scaffolded ../$(NAME) -- cd ../$(NAME) && make run"

# TODO: export target, once pico8 -export flag syntax/platforms are decided
# (breadjam bundles html/ + per-platform .bin dirs by hand today -- this
# should automate that). something like:
#
# export: build
# 	$(PICO8) -export "html.zip $(CART)"

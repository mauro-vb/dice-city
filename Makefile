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

# run every test headless, one cart per test (game + harness + one test, see
# build.py), so the tests never push a cart past 8192 tokens. a cart that
# doesn't finish in TEST_TIMEOUT seconds (e.g. "program too large", which makes
# pico8 hang) counts as a failure. snap("name") -> tests/snaps/name.png
TEST_TIMEOUT ?= 60
test:
	python3 build.py --test --name "$(PROJECT_NAME)" --author "$(AUTHOR)"
	@: > tests/.last_run.log
	@for c in tests/run_*.p8; do \
		timeout $(TEST_TIMEOUT) $(PICO8) -x $$c > tests/.cart.log 2>&1 \
			|| echo "FAIL $$c: timed out or crashed" >> tests/.cart.log; \
		grep -q "too large" tests/.cart.log && grep -h "tokens" tests/.cart.log | sed "s|^|FAIL $$c: too large |" >> tests/.cart.log; \
		cat tests/.cart.log >> tests/.last_run.log; \
	done; rm -f tests/.cart.log
	@python3 tests/snap.py > /dev/null
	@grep -E "^FAIL|error" tests/.last_run.log || true
	@awk '/^ok /{split($$2, a, "/"); p += a[1]; t += a[2]} END {print "ok " p "/" t}' tests/.last_run.log
	@! grep -qiE "^fail|error" tests/.last_run.log

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

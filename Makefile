SRC_DIR = src
TEST_DIR = spec

BUSTED = busted
LUAROCKS = luarocks
LUACHECK = luacheck

LUACHECKRC = luacheckrc

DEPENDENCIES = $(BUSTED) $(LUACHECK)

.PHONY: luacheck test dependencies each_version each_dependencies

all: test

dependencies:
	#) -- $@ --
	$(foreach package, $(DEPENDENCIES), \
		$(LUAROCKS) install --local $(package);)

luacheck: $(SRC_DIR) dependencies
	#) -- $@ --
	$(foreach file, $(wildcard $</*), $(LUACHECK) $(file);)
	$(foreach file, $(wildcard $(TEST_DIR)/*), $(LUACHECK) $(file);)

test: luacheck
	#) -- $@ --
	$(BUSTED) --verbose --keep-going  $(TEST_DIR)/*


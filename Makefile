.PHONY: build clean test

build:
	forge build

clean:
	rm -rf out

test: build
	evm -w test/Proxy.json
	forge test

define ASM_ARTIFACT
build: out/$(1).evm/$(1).json
out/$(1).evm/$(1).json: src/$(1).evm
	mkdir -p out/$(1).evm
ifneq (,$(findstring constructor,$(1)))
	jq -n --arg b "0x$$$$(evm $$<)" '{ bytecode: { object: $$$$b } }' > $$@
else
	jq -n --arg b "0x$$$$(evm -c $$<)" --arg d "0x$$$$(evm $$<)" '{ bytecode: { object: $$$$b }, deployedBytecode: { object: $$$$d } }' > $$@
endif
endef

ASM_SOURCE=$(wildcard src/*.evm)
$(foreach name, $(ASM_SOURCE:src/%.evm=%), $(eval $(call ASM_ARTIFACT,$(name))))

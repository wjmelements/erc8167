build:
	forge build

clean:
	rm -rf out

test: build
	forge test

define ASM_ARTIFACT
default: out/$(1).evm/$(1).json
out/$(1).evm/$(1).json: src/$(1).evm
	mkdir -p out/$(1).evm
	jq -n --arg b "0x$$$$(evm $$<)" '{ bytecode: { object: $$$$b } }' > $$@
endef

ASM_SOURCE=$(wildcard src/*.evm)
$(foreach name, $(ASM_SOURCE:src/%.evm=%), $(eval $(call ASM_ARTIFACT,$(name))))

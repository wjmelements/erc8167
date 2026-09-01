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

# Attach the ABI compiled from src/interfaces/$(1).sol, when that interface exists.
ABI_$(1) := $$(if $$(wildcard src/interfaces/$(1).sol),out/$(1).sol/$(1).json)
ifneq (,$$(ABI_$(1)))
ABI_ARG_$(1) := --slurpfile abi $$(ABI_$(1))
ABI_MERGE_$(1) := + { abi: $$$$abi[0].abi }
$$(ABI_$(1)): src/interfaces/$(1).sol
	forge build $$<
endif

out/$(1).evm/$(1).json: src/$(1).evm $$(ABI_$(1))
	mkdir -p out/$(1).evm
ifneq (,$(findstring constructor,$(1)))
	jq -n $$(ABI_ARG_$(1)) --arg b "0x$$$$(evm $$<)" '{ bytecode: { object: $$$$b } } $$(ABI_MERGE_$(1))' > $$@
else
	jq -n $$(ABI_ARG_$(1)) --arg b "0x$$$$(evm -c $$<)" --arg d "0x$$$$(evm $$<)" '{ bytecode: { object: $$$$b }, deployedBytecode: { object: $$$$d } } $$(ABI_MERGE_$(1))' > $$@
endif
endef

ASM_SOURCE=$(wildcard src/*.evm)
$(foreach name, $(ASM_SOURCE:src/%.evm=%), $(eval $(call ASM_ARTIFACT,$(name))))

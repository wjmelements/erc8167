out/%.out: src/%.evm
	evm $< > $@

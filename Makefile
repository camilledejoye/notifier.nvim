.PHONY: lint
lint:
	@luacheck lua

.PHONY: format
format:
	@stylua lua

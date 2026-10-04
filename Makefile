# By default all checks run inside the CI image (Dockerfile.ci), so no local
# luarocks/MSVC/LuaLS setup is needed (building luacheck natively is painful on Windows).
# Use `make USE_DOCKER=0 <target>` to run with locally installed tools instead.
USE_DOCKER ?= 1
CI_IMAGE ?= nvim-linux
PLENARY_REV := 74b06c6c75e4eeb3108ec01852001636d85a932b

MINIMAL_INIT := tests/minimal_init.lua
UNIT_CMD := PlenaryBustedDirectory tests/unit { minimal_init = '$(MINIMAL_INIT)' }

.PHONY: all test lint luals image

all: lint luals test

ifeq ($(USE_DOCKER),1)

# Dockerfile.ci copies nothing from the build context, so send an empty one.
# Layer caching makes repeated runs a no-op.
image:
	docker build -q -t $(CI_IMAGE) - < Dockerfile.ci

# MSYS_NO_PATHCONV stops Git Bash/MSYS from mangling the container paths on Windows.
DOCKER_RUN = MSYS_NO_PATHCONV=1 docker run --rm -v "$(CURDIR):/work" -w /work $(CI_IMAGE)

lint: image
	$(DOCKER_RUN) luacheck lua/ tests/ --config .luacheckrc

luals: image
	$(DOCKER_RUN) lua-language-server --check . --checklevel=Warning --configpath=.luarc.json

# The script below is single-quoted for sh, so the unit command needs double quotes inside.
DOCKER_UNIT_CMD := PlenaryBustedDirectory tests/unit { minimal_init = \"$(MINIMAL_INIT)\" }

# Same isolated-HOME setup as the Jenkins Unit stage; plenary is cloned fresh in the container.
test: image
	$(DOCKER_RUN) sh -ec ' \
	  export HOME=/tmp/home XDG_CONFIG_HOME=/tmp/config XDG_DATA_HOME=/tmp/data XDG_STATE_HOME=/tmp/state XDG_CACHE_HOME=/tmp/cache PLENARY_PATH=/tmp/plenary.nvim; \
	  mkdir -p $$HOME $$XDG_CONFIG_HOME $$XDG_DATA_HOME $$XDG_STATE_HOME $$XDG_CACHE_HOME; \
	  git clone -q --filter=blob:none https://github.com/nvim-lua/plenary.nvim $$PLENARY_PATH; \
	  git -C $$PLENARY_PATH checkout -q $(PLENARY_REV); \
	  nvim --headless -u $(MINIMAL_INIT) -c "$(DOCKER_UNIT_CMD)"'

else

MASON_BIN := $(HOME)/.local/share/nvim/mason/bin

# Prefer tools on PATH (CI image), fall back to local installs.
NVIM ?= nvim
LUACHECK ?= $(or $(shell command -v luacheck),$(wildcard $(HOME)/.luarocks/bin/luacheck),$(MASON_BIN)/luacheck)
LUALS ?= $(or $(shell command -v lua-language-server),$(MASON_BIN)/lua-language-server)

image:
	@true

test:
	$(NVIM) --headless -u $(MINIMAL_INIT) -c "$(UNIT_CMD)"

lint:
	$(LUACHECK) lua/ tests/ --config .luacheckrc

luals:
	$(LUALS) --check . --checklevel=Warning --configpath=.luarc.json

endif

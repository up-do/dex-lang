# To use installed executables instead of *.hs scripts, set these to true.
PKG_GROUPS_HS_EXE ?= false
PKGS_SORTED_HS_EXE ?= false
PKGS_UPGRADE_DONE_HS_EXE ?= false

include project-versions.mk
include updo/Makefile

.PHONY: all
all: projects

# To make stack.yaml or cabal.project and no other, mark the file we copy from
# as intermediate. This is all we want when not doing a GHC upgrade.
#
# Comment out these .INTERMEDIATE targets to allow these files to be kept.
.INTERMEDIATE: ghc-$(GHC_VERSION).$(CABAL_VIA).project
.INTERMEDIATE: ghc-$(GHC_UPGRADE).$(CABAL_VIA).project
.INTERMEDIATE: ghc-$(GHC_VERSION).$(STACK_VIA).yaml
.INTERMEDIATE: ghc-$(GHC_UPGRADE).$(STACK_VIA).yaml

.DEFAULT_GOAL := all

UPDO_VERSION ?= 7fa75f53441a5a4b858016744ec275a1e7b6a44a
UPDO_URL := https://github.com/cabalism/updo/archive/${UPDO_VERSION}.tar.gz

updo/Makefile:
	rm -rf updo
	curl -sSL ${UPDO_URL} | tar -xz
	mv updo-* updo
	chmod +x $$(grep -RIl '^#!' updo)

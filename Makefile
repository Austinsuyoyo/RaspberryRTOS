BUILDROOT_VERSION=2022.02.2
BUILDROOT_EXTERNAL=buildroot-external
BUILDROOT_PATCH=buildroot-patches
DEFCONFIG_DIR=$(BUILDROOT_EXTERNAL)/configs
DATE=$(shell date +%Y%m%d)
TARGET=
PRODUCT_VERSION=${DATE}
TARGETS:=$(sort $(notdir $(patsubst %_defconfig,%,$(wildcard $(DEFCONFIG_DIR)/*_defconfig))))
BR2_DL_DIR="../download"
BR2_CCACHE_DIR="${HOME}/.buildroot-ccache"
BR2_JLEVEL=0
# reference from buildroot
qstrip = $(strip $(subst ",,$(1)))
MESSAGE = echo "$(TERM_BOLD)>>>   $(call qstrip,$(1))$(TERM_RESET)"
TERM_BOLD := $(shell tput smso 2>/dev/null)
TERM_UNSERLINE := $(shell tput smul 2>/dev/null)
TERM_RESET := $(shell tput rmso 2>/dev/null)

# Needed for the foreach loops to loop over the list of hooks, so that
# each hook call is properly separated by a newline.
define sep


endef

ifneq ($(TARGET),)
	TARGETS:=$(TARGET)
else
	TARGET:=$(firstword $(TARGETS))
endif

.NOTPARALLEL: $(TARGETS) $(addsuffix -clean, $(TARGETS)) build-all clean-all 
.PHONY: all build clean distclean help

all: help

buildroot-$(BUILDROOT_VERSION).tar.xz:
	@$(call MESSAGE,"Downloading buildroot-$(BUILDROOT_VERSION).tar.xz")
	wget https://buildroot.org/downloads/buildroot-$(BUILDROOT_VERSION).tar.xz
	wget https://buildroot.org/downloads/buildroot-$(BUILDROOT_VERSION).tar.xz.sign
	cat buildroot-$(BUILDROOT_VERSION).tar.xz.sign | grep SHA1: | sed 's/^SHA1: //' | shasum -c

buildroot-$(BUILDROOT_VERSION): | buildroot-$(BUILDROOT_VERSION).tar.xz
	@$(call MESSAGE,"Patching to buildroot-$(BUILDROOT_VERSION)")
	if [ ! -d $@ ]; then tar xf buildroot-$(BUILDROOT_VERSION).tar.xz; for p in $(sort $(wildcard $(BUILDROOT_PATCH)/*.patch)); do echo "\nApplying $${p}"; patch -d buildroot-$(BUILDROOT_VERSION) --remove-empty-files -p1 < $${p} || exit 127; [ ! -x $${p%.*}.sh ] || $${p%.*}.sh buildroot-$(BUILDROOT_VERSION); done; fi

build-$(TARGET): | buildroot-$(BUILDROOT_VERSION) download
	mkdir -p build-$(TARGET)

download: buildroot-$(BUILDROOT_VERSION)
	mkdir -p download

config: | build-$(TARGET)
	@$(call MESSAGE,"Setup $(TARGET)_defconfig")
	cd build-$(TARGET) && $(MAKE) O=$(shell pwd)/build-$(TARGET) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) TARGET=$(TARGET) PRODUCT_VERSION=$(PRODUCT_VERSION) $(TARGET)_defconfig

build-all: $(TARGETS)
$(TARGETS): %: 
	@$(call MESSAGE,"Start Building $@")
	@$(MAKE) TARGET=$@ PRODUCT_VERSION=$(PRODUCT_VERSION) config
	@$(MAKE) TARGET=$@ PRODUCT_VERSION=$(PRODUCT_VERSION) build

build: | buildroot-$(BUILDROOT_VERSION)
	@$(call MESSAGE,"Building buildroot project $(TARGET)")
	cd build-$(TARGET) && $(MAKE) O=$(shell pwd)/build-$(TARGET) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) TARGET=$(TARGET) PRODUCT_VERSION=$(PRODUCT_VERSION)

clean-all: $(addsuffix -clean, $(TARGETS))
$(addsuffix -clean, $(TARGETS)): %:
	@$(MAKE) TARGET=$(subst -clean,,$@) PRODUCT_VERSION=$(PRODUCT_VERSION) clean

clean:
	@$(call MESSAGE,"Clean build-$(TARGET)")
	@rm -rf build-$(TARGET)

distclean: clean-all
	@$(call MESSAGE,"Clean everything start")
	@rm -rf buildroot-$(BUILDROOT_VERSION)
	@rm -f buildroot-$(BUILDROOT_VERSION).tar.xz buildroot-$(BUILDROOT_VERSION).tar.xz.sign
	@rm -rf download

.PHONY: menuconfig
menuconfig: buildroot-$(BUILDROOT_VERSION) build-$(TARGET)/.config
	cd build-$(TARGET) && $(MAKE) O=$(shell pwd)/build-$(TARGET) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) TARGET=$(TARGET) PRODUCT_VERSION=$(PRODUCT_VERSION) menuconfig

.PHONY: xconfig
xconfig: buildroot-$(BUILDROOT_VERSION) build-$(TARGET)/.config
	cd build-$(TARGET) && $(MAKE) O=$(shell pwd)/build-$(TARGET) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) TARGET=$(TARGET) PRODUCT_VERSION=$(PRODUCT_VERSION) xconfig

.PHONY: savedefconfig
savedefconfig: buildroot-$(BUILDROOT_VERSION) build-$(TARGET)
	cd build-$(TARGET) && $(MAKE) O=$(shell pwd)/build-$(TARGET) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) TARGET=$(TARGET) PRODUCT_VERSION=$(PRODUCT_VERSION) savedefconfig BR2_DEFCONFIG=../$(DEFCONFIG_DIR)/$(TARGET)_defconfig

# Create a fallback target (%) to forward all unknown target calls to the build Makefile.
# This includes:
#   linux-menuconfig
#   linux-update-defconfig
#   busybox-menuconfig
#   busybox-update-config
#   uboot-menuconfig
#   uboot-update-defconfig
linux-menuconfig linux-update-defconfig \
busybox-menuconfig busybox-update-config \
uboot-menuconfig uboot-update-defconfig \
graph-build graph-depends graph-size\
manual list-defconfigs legal-info:
	@$(call MESSAGE,"make $@ to $(TARGET)")
	@$(MAKE) -C build-$(TARGET) TARGET=$(TARGET) PRODUCT_VERSION=$(PRODUCT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) $@

help:
	@echo "Raspberry Pi Real Time OS Builder"
	@echo
	@echo "Usage:"
	@echo "  $(MAKE) <product>: build+create image for selected product"
	@echo "  $(MAKE) build-all: run build for all supported products"
	@echo
	@echo "  $(MAKE) <product>-clean: remove build directory for product"
	@echo "  $(MAKE) clean-all: remove build directories for all supported platforms"
	@echo
	@echo "  $(MAKE) distclean: clean everything (all build dirs and buildroot sources)"
	@echo
	@echo "Supported products: "
	$(foreach p,$(TARGETS), \
		@echo '   '$(p)$(sep))
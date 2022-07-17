################################################################################
#
# igh
#
################################################################################
IGH_VERSION = stable-1.5
IGH_SITE = $(call gitlab,etherlab.org,ethercat,$(IGH_VERSION))
IGH_SOURCE = ethercat-$(IGH_VERSION).tar.bz2
IGH_LICENSE = GPL-2.0 (IgH EtherCAT master), LGPL-2.1 (libraries)
IGH_LICENSE_FILES = COPYING COPYING.LESSER

IGH_INSTALL_STAGING = YES

IGH_CONF_OPTS = \
	--with-linux-dir=$(LINUX_DIR)

IGH_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_8139TOO),--enable-8139too,--disable-8139too)
IGH_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_E100),--enable-e100,--disable-e100)
IGH_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_E1000),--enable-e1000,--disable-e1000)
IGH_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_E1000E),--enable-e1000e,--disable-e1000e)
IGH_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_R8169),--enable-r8169,--disable-r8169)

define IGH_RUN_BOOTSTRAP
	cd $(@D); ./bootstrap
endef
IGH_PRE_CONFIGURE_HOOKS += IGH_RUN_BOOTSTRAP



$(eval $(kernel-module))
$(eval $(autotools-package))

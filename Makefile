include $(TOPDIR)/rules.mk 

PKG_NAME:=luci-app-k3screenctrl
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk


define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for k3screenctrl
	DEPENDS:=+bash +jsonfilter +wget +luci-compat
	PKGARCH:=arm_cortex-a9
	MAINTAINER:=yiguihai
endef

define Package/$(PKG_NAME)/description
	LuCI Support for k3screenctrl.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/
	cp -pR ./root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/k3screenctrl.zh-cn.po $(1)/usr/lib/lua/luci/i18n/k3screenctrl.zh-cn.lmo
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
  /etc/init.d/k3screenctrl disable
  /etc/init.d/k3screenctrl stop

  uci -q batch <<-EOF >/dev/null
    delete ucitrack.@k3screenctrl[-1]
    commit ucitrack
EOF

  rm -r /lib/k3screenctrl
  rm -rf /tmp/luci*
fi
exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
  chmod +x /etc/init.d/k3screenctrl
  chmod +x /usr/bin/k3screenctrl
  chmod -R +x /lib/k3screenctrl

  /etc/init.d/k3screenctrl enable

  rm -rf /tmp/luci*
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

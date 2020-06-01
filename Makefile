TARGET = iphone:clang:11.2
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUp
$(TWEAK_NAME)_FILES = NextUp.xm NextUpManager.xm NextUpViewController.xm Common.xm SettingsKeys.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

ifdef SB_ONLY
after-install::
	install.exec "killall -9 SpringBoard"
else ifdef CLIENTS_ONLY
after-install::
	install.exec "killall -9 Spotify TIDAL"
endif

SUBPROJECTS += clients
SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

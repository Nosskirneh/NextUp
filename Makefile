TARGET = iphone:clang:11.2
ifdef DEBUG
	ARCHS = arm64
else
	ARCHS = arm64 arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUp
$(TWEAK_NAME)_FILES = NextUp.xm NextUpManager.xm NextUpViewController.xm Common.xm SettingsKeys.m NUCenter.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += clients
SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

TARGET = iphone:clang:11.2
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUpClients
$(TWEAK_NAME)_FILES = $(wildcard */*.xm) CommonClients.xm ../Common.xm ../NUCenter.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Anghami"

TARGET = iphone:clang:9.2
ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUMusi
$(TWEAK_NAME)_FILES = Musi.xm ../../Common.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Musi"

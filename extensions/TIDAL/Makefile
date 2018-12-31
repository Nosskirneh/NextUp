TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUTIDAL
NUTIDAL_FILES = TIDAL.xm ../../Common.xm
NUTIDAL_CFLAGS = -fobjc-arc
NUTIDAL_LIBRARIES = rocketbootstrap
NUTIDAL_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 TIDAL"

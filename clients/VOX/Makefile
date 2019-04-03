include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUVOX
NUVOX_FILES = VOX.xm ../../Common.xm
NUVOX_CFLAGS = -fobjc-arc
NUVOX_LIBRARIES = rocketbootstrap
NUVOX_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 VOX"

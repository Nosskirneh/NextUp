TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUSoundCloud
NUSoundCloud_FILES = SoundCloud.xm ../../Common.xm
NUSoundCloud_CFLAGS = -fobjc-arc
NUSoundCloud_LIBRARIES = rocketbootstrap
NUSoundCloud_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SoundCloud"

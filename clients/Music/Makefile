TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUMusic
NUMusic_FILES = Music.xm ../../Common.xm
NUMusic_CFLAGS = -fobjc-arc
NUMusic_LIBRARIES = rocketbootstrap
NUMusic_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Music"

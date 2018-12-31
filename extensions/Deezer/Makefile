TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUDeezer
NUDeezer_FILES = Deezer.xm ../../Common.xm
NUDeezer_CFLAGS = -fobjc-arc
NUDeezer_LIBRARIES = rocketbootstrap
NUDeezer_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Deezer"

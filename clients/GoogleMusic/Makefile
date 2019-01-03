TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUGoogleMusic
NUGoogleMusic_FILES = GoogleMusic.xm ../../Common.xm
NUGoogleMusic_CFLAGS = -fobjc-arc
NUGoogleMusic_LIBRARIES = rocketbootstrap
NUGoogleMusic_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 GoogleMusic"

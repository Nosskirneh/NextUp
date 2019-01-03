TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUYouTubeMusic
NUYouTubeMusic_FILES = YouTubeMusic.xm ../../Common.xm
NUYouTubeMusic_CFLAGS = -fobjc-arc
NUYouTubeMusic_LIBRARIES = rocketbootstrap
NUYouTubeMusic_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 YouTubeMusic"

TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUSpotify
NUSpotify_FILES = Spotify.xm ../../Common.xm
NUSpotify_CFLAGS = -fobjc-arc
NUSpotify_LIBRARIES = rocketbootstrap
NUSpotify_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Spotify"

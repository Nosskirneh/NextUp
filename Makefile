TARGET = iphone:clang:9.2
ARCHS = armv7 arm64 #arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUp
NextUp_FILES = NextUp.xm Common.xm NextUpManager.m NextUpViewController.xm
NextUp_CFLAGS = -fobjc-arc
NextUp_LIBRARIES = rocketbootstrap
NextUp_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += clients/Anghami
SUBPROJECTS += clients/Deezer
SUBPROJECTS += clients/GoogleMusic
SUBPROJECTS += clients/Music
SUBPROJECTS += clients/Podcasts
SUBPROJECTS += clients/SoundCloud
SUBPROJECTS += clients/Spotify
SUBPROJECTS += clients/TIDAL
SUBPROJECTS += clients/YouTubeMusic
SUBPROJECTS += clients/VOX
SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

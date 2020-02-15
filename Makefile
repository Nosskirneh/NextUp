TARGET = iphone:clang:11.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUp
$(TWEAK_NAME)_FILES = NextUp.xm NextUpManager.xm NextUpViewController.xm Common.xm SettingsKeys.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += clients/Anghami
SUBPROJECTS += clients/Deezer
SUBPROJECTS += clients/JioSaavn
SUBPROJECTS += clients/GoogleMusic
SUBPROJECTS += clients/Music
SUBPROJECTS += clients/Podcasts
SUBPROJECTS += clients/SoundCloud
SUBPROJECTS += clients/TIDAL
SUBPROJECTS += clients/YouTubeMusic
SUBPROJECTS += clients/VOX
SUBPROJECTS += clients/Musi
SUBPROJECTS += clients/Napster
SUBPROJECTS += clients/AudioMack
SUBPROJECTS += clients/JetAudio
SUBPROJECTS += clients/Spotify
SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

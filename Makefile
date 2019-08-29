TARGET = iphone:clang:9.2
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUp
$(TWEAK_NAME)_FILES = NextUp.xm SettingsKeys.m Common.xm NextUpManager.xm NextUpViewController.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"

# SUBPROJECTS += clients/Anghami
# SUBPROJECTS += clients/Deezer
# SUBPROJECTS += clients/JioSaavn
# SUBPROJECTS += clients/GoogleMusic
# SUBPROJECTS += clients/Music
# SUBPROJECTS += clients/Podcasts
# SUBPROJECTS += clients/SoundCloud
# SUBPROJECTS += clients/TIDAL
# SUBPROJECTS += clients/YouTubeMusic
# SUBPROJECTS += clients/VOX
# SUBPROJECTS += clients/Musi
# SUBPROJECTS += clients/Napster
SUBPROJECTS += clients/Spotify
SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

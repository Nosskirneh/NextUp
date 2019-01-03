TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUPodcasts
NUPodcasts_FILES = Podcasts.xm ../../Common.xm
NUPodcasts_CFLAGS = -fobjc-arc
NUPodcasts_LIBRARIES = rocketbootstrap
NUPodcasts_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Podcasts"

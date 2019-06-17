TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUDeezer
$(TWEAK_NAME)_FILES = Deezer.xm ../CommonClients.xm ../../Common.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Deezer"

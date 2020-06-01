TARGET = iphone:clang:11.2
ifdef DEBUG
	ARCHS = arm64
else
	ARCHS = arm64 arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUpClients
$(TWEAK_NAME)_FILES = $(wildcard */*.xm) CommonClients.xm ../Common.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Anghami"

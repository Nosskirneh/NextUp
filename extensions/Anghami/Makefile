TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NUAnghami
NUAnghami_FILES = Anghami.xm ../../Common.xm
NUAnghami_CFLAGS = -fobjc-arc
NUAnghami_LIBRARIES = rocketbootstrap
NUAnghami_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Anghami"

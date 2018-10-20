TARGET = iphone:clang:9.2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NextUp
NextUp_FILES = NextUp.xm Common.xm NUMetadataSaver.m NextUpViewController.xm
NextUp_CFLAGS = -fobjc-arc
NextUp_LIBRARIES = rocketbootstrap
NextUp_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/aggregate.mk

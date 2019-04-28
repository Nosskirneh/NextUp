include $(THEOS)/makefiles/common.mk

TARGET = iphone:clang:9.2
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 9.2
ARCHS = armv7 arm64 #arm64e

BUNDLE_NAME = NextUpPrefs
$(BUNDLE_NAME)_FILES = NextUpRootListController.m ../../DRM/PFStatusBarAlert/PFStatusBarAlert.mm ../../TwitterStuff/Prompt.m
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_OBJ_FILES = $(THEOS)/lib/libPayPalMobile.a
$(BUNDLE_NAME)_FRAMEWORKS = Accelerate, AudioToolbox, AVFoundation, CoreLocation, CoreMedia, \
						   MessageUI, MobileCoreServices, SystemConfiguration, SafariServices

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NextUp.plist$(ECHO_END)

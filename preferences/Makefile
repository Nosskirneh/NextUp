include $(THEOS)/makefiles/common.mk

TARGET = iphone:clang:9.2
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 9.2

BUNDLE_NAME = NextUpPrefs
$(TWEAK_NAME)_FILES = NextUpRootListController.m ../../DRM/PFStatusBarAlert/PFStatusBarAlert.mm ../../TwitterStuff/Prompt.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(TWEAK_NAME)_OBJ_FILES = $(THEOS)/lib/libPayPalMobile.a
$(TWEAK_NAME)_FRAMEWORKS = Accelerate, AudioToolbox, AVFoundation, CoreLocation, CoreMedia, \
						 MessageUI, MobileCoreServices, SystemConfiguration, SafariServices

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NextUp.plist$(ECHO_END)

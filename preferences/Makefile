include $(THEOS)/makefiles/common.mk

TARGET = iphone:clang:9.2
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 9.2

BUNDLE_NAME = NextUpPrefs
NextUpPrefs_FILES = NextUpRootListController.m ../../DRM/PFStatusBarAlert/PFStatusBarAlert.mm ../../TwitterStuff/Prompt.m
NextUpPrefs_CFLAGS = -fobjc-arc
NextUpPrefs_INSTALL_PATH = /Library/PreferenceBundles
NextUpPrefs_PRIVATE_FRAMEWORKS = Preferences
NextUpPrefs_OBJ_FILES = $(THEOS)/lib/libPayPalMobile.a
NextUpPrefs_FRAMEWORKS = Accelerate, AudioToolbox, AVFoundation, CoreLocation, CoreMedia, \
						 MessageUI, MobileCoreServices, SystemConfiguration, SafariServices

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NextUp.plist$(ECHO_END)

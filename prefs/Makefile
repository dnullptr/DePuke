THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DePukePrefs

DePukePrefs_FILES = DePukeListController.m
DePukePrefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore
DePukePrefs_LDFLAGS = -undefined dynamic_lookup
DePukePrefs_INSTALL_PATH = /Library/PreferenceBundles
DePukePrefs_CFLAGS = -fobjc-arc -I../ -Wall

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/DePukePrefs.plist$(ECHO_END)

include $(THEOS_MAKE_PATH)/bundle.mk

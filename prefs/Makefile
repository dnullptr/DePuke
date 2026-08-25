THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DePukePrefs

DePukePrefs_FILES = DePukeListController.m
DePukePrefs_FRAMEWORKS = UIKit
DePukePrefs_PRIVATE_FRAMEWORKS = Preferences
DePukePrefs_INSTALL_PATH = /Library/PreferenceBundles
DePukePrefs_CFLAGS = -fobjc-arc -I../ -Wall

include $(THEOS_MAKE_PATH)/bundle.mk

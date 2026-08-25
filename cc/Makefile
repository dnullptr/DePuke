THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DePukeCC
DePukeCC_BUNDLE_EXTENSION = bundle
DePukeCC_FILES = DePukeCC.m
DePukeCC_FRAMEWORKS = UIKit QuartzCore
DePukeCC_LDFLAGS = -undefined dynamic_lookup
DePukeCC_INSTALL_PATH = /Library/ControlCenter/Bundles
DePukeCC_CFLAGS = -fobjc-arc -I../ -Wall

include $(THEOS_MAKE_PATH)/bundle.mk

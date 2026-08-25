TARGET := iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DePuke

DePuke_FILES = Tweak.x DePukeManager.m DePukeOverlayWindow.m
DePuke_CFLAGS = -fobjc-arc -I. -Wall
DePuke_FRAMEWORKS = UIKit CoreGraphics CoreMotion QuartzCore CoreLocation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs cc
include $(THEOS_MAKE_PATH)/aggregate.mk

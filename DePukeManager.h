#pragma once

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import "DePukeOverlayWindow.h"

@interface DePukeManager : NSObject

@property (nonatomic, strong, readonly) DePukeOverlayWindow *overlayWindow;

// Preferences
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) CGFloat sensitivity;
@property (nonatomic, assign) CGFloat dotSize;
@property (nonatomic, assign) NSInteger dotCount;
@property (nonatomic, assign) CGFloat dotAlpha;
@property (nonatomic, assign) CGFloat smoothingAlpha;
@property (nonatomic, assign) CGFloat maxOffset;
@property (nonatomic, assign) BOOL autoDetect;
@property (nonatomic, assign) NSInteger themeMode;

+ (instancetype)sharedInstance;

- (void)setupOverlay;
- (void)loadPreferences;
- (void)startMotionUpdates;
- (void)stopMotionUpdates;
- (void)updateOverlayVisibility;

@end

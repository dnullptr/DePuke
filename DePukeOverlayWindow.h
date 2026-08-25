#pragma once

#import <UIKit/UIKit.h>

@interface UIWindow (DePukePrivate)
- (void)_setSecure:(BOOL)secure;
- (BOOL)_isSecure;
@end

@class DePukeDotView;

@interface DePukeOverlayViewController : UIViewController
@end

@interface DePukeOverlayWindow : UIWindow

@property (nonatomic, strong, readonly) NSMutableArray<DePukeDotView *> *dotViews;
@property (nonatomic, assign) CGFloat dotSize;
@property (nonatomic, assign) NSInteger dotCount;
@property (nonatomic, assign) CGFloat dotAlpha;

- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene;
- (void)configureDotsWithCount:(NSInteger)count size:(CGFloat)size alpha:(CGFloat)alpha themeMode:(NSInteger)themeMode;
- (void)applyMotionOffset:(CGPoint)offset;
- (void)relayoutDots;

@end

@interface DePukeDotView : UIView
@property (nonatomic, assign) CGPoint baseCenter;
@property (nonatomic, assign) NSInteger edgePlacement; // 0: Top, 1: Bottom, 2: Left, 3: Right
- (void)applyTheme:(NSInteger)themeMode alpha:(CGFloat)alpha;
@end

#import "DePukeOverlayWindow.h"

#pragma mark - DePukeDotView Implementation

@implementation DePukeDotView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.85];
        self.layer.masksToBounds = NO;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 1.5);
        self.layer.shadowRadius = 3.0;
        self.layer.shadowOpacity = 0.35;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
}

- (void)applyTheme:(NSInteger)themeMode alpha:(CGFloat)alpha {
    self.alpha = alpha;
    switch (themeMode) {
        case 1: // Light
            self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:alpha];
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOpacity = 0.25;
            break;
        case 2: // Dynamic Accent (Cyan / Blue)
            self.backgroundColor = [UIColor colorWithRed:0.20 green:0.60 blue:1.0 alpha:alpha];
            self.layer.shadowColor = [UIColor colorWithRed:0.10 green:0.40 blue:0.9 alpha:0.5].CGColor;
            self.layer.shadowOpacity = 0.6;
            break;
        case 0: // Dark / Default iOS 18 style
        default:
            self.backgroundColor = [UIColor colorWithWhite:0.12 alpha:alpha];
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOpacity = 0.35;
            break;
    }
}

@end

#pragma mark - DePukeOverlayViewController Implementation

@interface DePukeOverlayViewController ()
@property (nonatomic, weak) DePukeOverlayWindow *overlayWindow;
@end

@implementation DePukeOverlayViewController

- (instancetype)initWithOverlayWindow:(DePukeOverlayWindow *)window {
    self = [super init];
    if (self) {
        _overlayWindow = window;
    }
    return self;
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor clearColor];
    view.userInteractionEnabled = NO;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.overlayWindow relayoutDots];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.overlayWindow relayoutDots];
    }];
}

@end

#pragma mark - DePukeOverlayWindow Implementation

@interface DePukeOverlayWindow ()
@property (nonatomic, strong, readwrite) NSMutableArray<DePukeDotView *> *dotViews;
@property (nonatomic, strong) DePukeOverlayViewController *overlayRootVC;
@property (nonatomic, assign) NSInteger currentThemeMode;
@end

@implementation DePukeOverlayWindow

- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    if (windowScene) {
        self = [super initWithWindowScene:windowScene];
    } else {
        self = [super initWithFrame:[UIScreen mainScreen].bounds];
    }
    
    if (self) {
        _dotViews = [NSMutableArray array];
        _dotSize = 8.0;
        _dotCount = 8;
        _dotAlpha = 0.75;
        _currentThemeMode = 0;
        
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.windowLevel = UIWindowLevelStatusBar + 1000.0;
        self.hidden = YES;
        
        _overlayRootVC = [[DePukeOverlayViewController alloc] initWithOverlayWindow:self];
        self.rootViewController = _overlayRootVC;
        
        if ([self respondsToSelector:@selector(_setSecure:)]) {
            [self _setSecure:YES];
        }
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Crucial requirement: complete pass-through so underlying views receive all touch events
    return nil;
}

- (BOOL)_canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)_canAffectStatusBarAppearance {
    return NO;
}

- (void)configureDotsWithCount:(NSInteger)count size:(CGFloat)size alpha:(CGFloat)alpha themeMode:(NSInteger)themeMode {
    self.dotCount = count;
    self.dotSize = size;
    self.dotAlpha = alpha;
    self.currentThemeMode = themeMode;
    
    // Remove existing dots
    for (DePukeDotView *dot in self.dotViews) {
        [dot removeFromSuperview];
    }
    [self.dotViews removeAllObjects];
    
    // Create new dots
    // Apple Vehicle Motion Cues distributes dots along the screen edges:
    // Typically 2 along top, 2 along bottom, 2 along left, 2 along right for count=8
    NSInteger perSide = MAX(1, count / 4);
    NSInteger total = perSide * 4;
    
    for (NSInteger i = 0; i < total; i++) {
        DePukeDotView *dot = [[DePukeDotView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        dot.edgePlacement = i / perSide; // 0: Top, 1: Bottom, 2: Left, 3: Right
        [dot applyTheme:themeMode alpha:alpha];
        [self.rootViewController.view addSubview:dot];
        [self.dotViews addObject:dot];
    }
    
    [self relayoutDots];
}

- (void)relayoutDots {
    if (self.dotViews.count == 0) return;
    
    CGRect bounds = self.rootViewController.view.bounds;
    if (CGRectIsEmpty(bounds)) {
        bounds = [UIScreen mainScreen].bounds;
    }
    
    UIEdgeInsets insets = UIEdgeInsetsMake(36.0, 20.0, 36.0, 20.0);
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safe = self.safeAreaInsets;
        insets.top = MAX(insets.top, safe.top + 16.0);
        insets.bottom = MAX(insets.bottom, safe.bottom + 16.0);
        insets.left = MAX(insets.left, safe.left + 16.0);
        insets.right = MAX(insets.right, safe.right + 16.0);
    }
    
    NSInteger perSide = self.dotViews.count / 4;
    if (perSide <= 0) return;
    
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    
    for (NSInteger i = 0; i < self.dotViews.count; i++) {
        DePukeDotView *dot = self.dotViews[i];
        NSInteger side = i / perSide;
        NSInteger indexInSide = i % perSide;
        
        CGPoint baseCenter = CGPointZero;
        CGFloat step = 1.0 / (CGFloat)(perSide + 1);
        CGFloat fraction = (indexInSide + 1) * step;
        
        switch (side) {
            case 0: // Top edge
                baseCenter = CGPointMake(insets.left + (width - insets.left - insets.right) * fraction, insets.top);
                break;
            case 1: // Bottom edge
                baseCenter = CGPointMake(insets.left + (width - insets.left - insets.right) * fraction, height - insets.bottom);
                break;
            case 2: // Left edge
                baseCenter = CGPointMake(insets.left, insets.top + (height - insets.top - insets.bottom) * fraction);
                break;
            case 3: // Right edge
                baseCenter = CGPointMake(width - insets.right, insets.top + (height - insets.top - insets.bottom) * fraction);
                break;
        }
        
        dot.bounds = CGRectMake(0, 0, self.dotSize, self.dotSize);
        dot.center = baseCenter;
        dot.baseCenter = baseCenter;
        [dot layoutIfNeeded];
    }
}

- (void)applyMotionOffset:(CGPoint)offset {
    for (DePukeDotView *dot in self.dotViews) {
        dot.transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
    }
}

@end

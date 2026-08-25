#import "DePukeManager.h"
#import "Tweak.h"

@interface DePukeManager () {
    CGPoint _filteredOffset;
    CGPoint _currentVelocity;
}

@property (nonatomic, strong, readwrite) DePukeOverlayWindow *overlayWindow;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) NSOperationQueue *activityQueue;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL isAutomotive;
@property (nonatomic, assign) BOOL isUpdatingMotion;

@end

@implementation DePukeManager

+ (instancetype)sharedInstance {
    static DePukeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DePukeManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = YES;
        _sensitivity = 1.0;
        _dotSize = 8.0;
        _dotCount = 8;
        _dotAlpha = 0.75;
        _smoothingAlpha = 0.15;
        _maxOffset = 40.0;
        _autoDetect = NO;
        _themeMode = 0;
        _isAutomotive = NO;
        _filteredOffset = CGPointZero;
        _currentVelocity = CGPointZero;
        
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        
        if ([CMMotionActivityManager isActivityAvailable]) {
            _activityManager = [[CMMotionActivityManager alloc] init];
            _activityQueue = [[NSOperationQueue alloc] init];
            _activityQueue.maxConcurrentOperationCount = 1;
            _activityQueue.qualityOfService = NSQualityOfServiceBackground;
        }
    }
    return self;
}

- (void)setupOverlay {
    if (self.overlayWindow) return;
    
    UIWindowScene *activeScene = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
        if (!activeScene) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    activeScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }
    }
    
    self.overlayWindow = [[DePukeOverlayWindow alloc] initWithWindowScene:activeScene];
    [self.overlayWindow configureDotsWithCount:self.dotCount
                                         size:self.dotSize
                                        alpha:self.dotAlpha
                                    themeMode:self.themeMode];
    
    [self updateOverlayVisibility];
}

- (void)loadPreferences {
    NSString *path = DePukePreferencePath();
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (prefs) {
        id enabledVal = prefs[kDePukeEnabledKey];
        self.enabled = enabledVal ? [enabledVal boolValue] : YES;
        
        id sensVal = prefs[kDePukeSensitivityKey];
        self.sensitivity = sensVal ? [sensVal doubleValue] : 1.0;
        
        id sizeVal = prefs[kDePukeDotSizeKey];
        self.dotSize = sizeVal ? [sizeVal doubleValue] : 8.0;
        
        id countVal = prefs[kDePukeDotCountKey];
        self.dotCount = countVal ? [countVal integerValue] : 8;
        
        id alphaVal = prefs[kDePukeDotAlphaKey];
        self.dotAlpha = alphaVal ? [alphaVal doubleValue] : 0.75;
        
        id smoothVal = prefs[kDePukeSmoothingKey];
        self.smoothingAlpha = smoothVal ? [smoothVal doubleValue] : 0.15;
        
        id autoVal = prefs[kDePukeAutoDetectKey];
        self.autoDetect = autoVal ? [autoVal boolValue] : NO;
        
        id maxOffsetVal = prefs[kDePukeMaxOffsetKey];
        self.maxOffset = maxOffsetVal ? [maxOffsetVal doubleValue] : 40.0;
        
        id themeVal = prefs[kDePukeThemeModeKey];
        self.themeMode = themeVal ? [themeVal integerValue] : 0;
    }
    
    if (self.overlayWindow) {
        [self.overlayWindow configureDotsWithCount:self.dotCount
                                             size:self.dotSize
                                            alpha:self.dotAlpha
                                        themeMode:self.themeMode];
    }
    
    [self updateOverlayVisibility];
    [self configureActivityTracking];
}

- (void)configureActivityTracking {
    if (!self.activityManager) return;
    
    if (self.enabled && self.autoDetect) {
        [self.activityManager startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isAutomotive = activity.automotive;
                [self updateOverlayVisibility];
            });
        }];
    } else {
        [self.activityManager stopActivityUpdates];
        self.isAutomotive = NO;
    }
}

- (void)updateOverlayVisibility {
    BOOL shouldBeActive = self.enabled;
    if (self.autoDetect) {
        shouldBeActive = self.enabled && self.isAutomotive;
    }
    
    if (shouldBeActive) {
        if (!self.isUpdatingMotion) {
            [self startMotionUpdates];
        }
        if (self.overlayWindow) {
            self.overlayWindow.hidden = NO;
        }
    } else {
        if (self.isUpdatingMotion) {
            [self stopMotionUpdates];
        }
        if (self.overlayWindow) {
            self.overlayWindow.hidden = YES;
            [self.overlayWindow applyMotionOffset:CGPointZero];
        }
        _filteredOffset = CGPointZero;
    }
}

- (void)startMotionUpdates {
    if (self.isUpdatingMotion) return;
    
    if (self.motionManager.isDeviceMotionAvailable) {
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
        
        if (!self.displayLink) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLinkTick:)];
            if (@available(iOS 15.0, *)) {
                CAFrameRateRange range = CAFrameRateRangeMake(60.0, 120.0, 60.0);
                self.displayLink.preferredFrameRateRange = range;
            }
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
        self.isUpdatingMotion = YES;
    }
}

- (void)stopMotionUpdates {
    if (!self.isUpdatingMotion) return;
    
    [self.motionManager stopDeviceMotionUpdates];
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    self.isUpdatingMotion = NO;
}

- (void)onDisplayLinkTick:(CADisplayLink *)link {
    CMDeviceMotion *motion = self.motionManager.deviceMotion;
    if (!motion) return;
    
    // User acceleration is measured in Gs (1.0 = ~9.81 m/s^2)
    CMAcceleration userAccel = motion.userAcceleration;
    
    // Determine screen orientation to project coordinates accurately
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = self.overlayWindow.windowScene;
        if (scene) {
            orientation = scene.interfaceOrientation;
        }
    }
    
    CGFloat rawLateralG = 0.0;
    CGFloat rawLongitudinalG = 0.0;
    
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rawLateralG = -userAccel.y;
            rawLongitudinalG = userAccel.x;
            break;
        case UIInterfaceOrientationLandscapeRight:
            rawLateralG = userAccel.y;
            rawLongitudinalG = -userAccel.x;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rawLateralG = -userAccel.x;
            rawLongitudinalG = -userAccel.y;
            break;
        case UIInterfaceOrientationPortrait:
        default:
            rawLateralG = userAccel.x;
            rawLongitudinalG = userAccel.y;
            break;
    }
    
    // Invert mapping per Vehicle Motion Cues design:
    // Vehicle accelerates forward -> visual dots slide toward the bottom (+y)
    // Vehicle brakes -> visual dots slide toward the top (-y)
    // Vehicle turns left (centrifugal force pushes right) -> visual dots slide right (+x)
    // Vehicle turns right (centrifugal force pushes left) -> visual dots slide left (-x)
    CGFloat targetDx = -rawLateralG * 100.0 * self.sensitivity;
    CGFloat targetDy = rawLongitudinalG * 100.0 * self.sensitivity;
    
    // Deadband filter to prevent micro-jitter during idle stop
    if (fabs(targetDx) < 1.0) targetDx = 0.0;
    if (fabs(targetDy) < 1.0) targetDy = 0.0;
    
    // Clamp to maximum allowed offset
    CGFloat maxLimit = self.maxOffset;
    targetDx = MAX(-maxLimit, MIN(maxLimit, targetDx));
    targetDy = MAX(-maxLimit, MIN(maxLimit, targetDy));
    
    // Discrete Low-Pass Filter (LPF):
    // filteredValue = alpha * rawValue + (1.0 - alpha) * previousFilteredValue
    CGFloat alpha = MAX(0.01, MIN(1.0, self.smoothingAlpha));
    _filteredOffset.x = (alpha * targetDx) + ((1.0 - alpha) * _filteredOffset.x);
    _filteredOffset.y = (alpha * targetDy) + ((1.0 - alpha) * _filteredOffset.y);
    
    // Apply transform directly to overlay window dots
    [self.overlayWindow applyMotionOffset:_filteredOffset];
}

- (void)dealloc {
    [self stopMotionUpdates];
    if (_activityManager) {
        [_activityManager stopActivityUpdates];
    }
}

@end

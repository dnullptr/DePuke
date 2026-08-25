#import "DePukeCC.h"
#import "../Tweak.h"
#import <dlfcn.h>

__attribute__((constructor))
static void DePukeCCInit(void) {
    dlopen("/System/Library/PrivateFrameworks/ControlCenterUIKit.framework/ControlCenterUIKit", RTLD_NOW);
    dlopen("/System/Library/PrivateFrameworks/ControlCenterUI.framework/ControlCenterUI", RTLD_NOW);
}

static void CCReloadPreferencesNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    DePukeCC *module = (__bridge DePukeCC *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [module refreshState];
    });
}

@implementation DePukeCC

- (instancetype)init {
    self = [super init];
    if (self) {
        // Register observer to keep CC tile state synchronized if changed via Settings
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            CCReloadPreferencesNotificationCallback,
            CFSTR(DEPUKE_RELOAD_NOTIFICATION),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

- (UIImage *)iconGlyph {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24.0 weight:UIImageSymbolWeightMedium];
    UIImage *img = [UIImage systemImageNamed:@"car.side.fill" withConfiguration:config];
    if (!img) {
        img = [UIImage systemImageNamed:@"car.fill" withConfiguration:config];
    }
    return img;
}

- (UIImage *)selectedIconGlyph {
    return [self iconGlyph];
}

- (UIColor *)selectedColor {
    return [UIColor colorWithRed:0.20 green:0.60 blue:1.0 alpha:1.0];
}

- (BOOL)isSelected {
    NSString *path = DePukePreferencePath();
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:path];
    if (prefs && prefs[kDePukeEnabledKey]) {
        return [prefs[kDePukeEnabledKey] boolValue];
    }
    return YES;
}

- (void)setSelected:(BOOL)selected {
    NSString *path = DePukePreferencePath();
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (!prefs) {
        prefs = [NSMutableDictionary dictionary];
    }
    prefs[kDePukeEnabledKey] = @(selected);
    
    // Ensure parent directory exists before writing
    NSString *parentDir = [path stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:parentDir withIntermediateDirectories:YES attributes:nil error:nil];
    [prefs writeToFile:path atomically:YES];

    // Post Darwin notification to update SpringBoard overlay live
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR(DEPUKE_RELOAD_NOTIFICATION),
        NULL,
        NULL,
        true
    );

    [super refreshState];
}

- (void)dealloc {
    CFNotificationCenterRemoveObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self),
        CFSTR(DEPUKE_RELOAD_NOTIFICATION),
        NULL
    );
}

@end

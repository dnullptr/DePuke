#import "Tweak.h"
#import "DePukeManager.h"

static void ReloadPreferencesNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DePukeManager sharedInstance] loadPreferences];
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // Initialize DePuke on SpringBoard launch
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DePukeManager sharedInstance] setupOverlay];
        [[DePukeManager sharedInstance] loadPreferences];
    });
}

%end

%ctor {
    @autoreleasepool {
        // Register Darwin notification listener for live preference reloading without respring
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            ReloadPreferencesNotificationCallback,
            CFSTR(DEPUKE_RELOAD_NOTIFICATION),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
}

#pragma once

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>

#define DEPUKE_PREF_DOMAIN @"com.dnullptr.depuke"
#define DEPUKE_RELOAD_NOTIFICATION "com.dnullptr.depuke/ReloadPrefs"

// Rootless vs Rootful Preference Path Helper
static inline NSString *DePukePreferencePath(void) {
    NSString *rootlessPath = @"/var/jb/var/mobile/Library/Preferences/com.dnullptr.depuke.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootlessPath]) {
        return rootlessPath;
    }
    return @"/var/mobile/Library/Preferences/com.dnullptr.depuke.plist";
}

// Preference Keys
static NSString * const kDePukeEnabledKey      = @"kEnabled";
static NSString * const kDePukeSensitivityKey  = @"kSensitivity";
static NSString * const kDePukeDotSizeKey      = @"kDotSize";
static NSString * const kDePukeDotCountKey     = @"kDotCount";
static NSString * const kDePukeDotAlphaKey     = @"kDotAlpha";
static NSString * const kDePukeSmoothingKey    = @"kSmoothing";
static NSString * const kDePukeAutoDetectKey   = @"kAutoDetect";
static NSString * const kDePukeMaxOffsetKey    = @"kMaxOffset";
static NSString * const kDePukeThemeModeKey    = @"kThemeMode";

// Forward Declarations for SpringBoard
@interface SpringBoard : UIApplication
@end

@interface UIWindow (SpringBoardPrivate)
- (void)_setSecure:(BOOL)secure;
@end

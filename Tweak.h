#pragma once

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>

#define DEPUKE_PREF_DOMAIN @"com.dnullptr.depuke"
#define DEPUKE_RELOAD_NOTIFICATION "com.dnullptr.depuke/ReloadPrefs"

// Jailbreak root path helper: works for rootful, rootless (/var/jb) and roothide (randomized jbroot)
#if __has_include(<roothide.h>)
#import <roothide.h>
#define DEPUKE_JBROOT(path) jbroot((NSString *)(path))
#else
#import <rootless.h>
#define DEPUKE_JBROOT(path) ROOT_PATH_NS_VAR(path)
#endif

// Preferences go through cfprefsd (same store PreferenceLoader's PSListController uses),
// so we never depend on where the plist physically lives (/var/mobile, /var/jb or jbroot).
static inline NSDictionary *DePukeCopyPreferences(void) {
    CFStringRef domain = (__bridge CFStringRef)DEPUKE_PREF_DOMAIN;
    CFPreferencesAppSynchronize(domain);
    CFArrayRef keys = CFPreferencesCopyKeyList(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keys) return @{};
    CFDictionaryRef dict = CFPreferencesCopyMultiple(keys, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFRelease(keys);
    return dict ? (__bridge_transfer NSDictionary *)dict : @{};
}

static inline void DePukeSetPreference(NSString *key, id value) {
    CFStringRef domain = (__bridge CFStringRef)DEPUKE_PREF_DOMAIN;
    CFPreferencesSetValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesAppSynchronize(domain);
}

static inline void DePukeResetPreferences(void) {
    CFStringRef domain = (__bridge CFStringRef)DEPUKE_PREF_DOMAIN;
    CFArrayRef keys = CFPreferencesCopyKeyList(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (keys) {
        CFPreferencesSetMultiple(NULL, keys, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFRelease(keys);
    }
    CFPreferencesAppSynchronize(domain);
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

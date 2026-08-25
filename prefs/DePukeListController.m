#import "DePukeListController.h"
#import "../Tweak.h"
#import <spawn.h>
#import <unistd.h>

extern char **environ;

@implementation DePukeListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring"
                                                                   message:@"Are you sure you want to respring SpringBoard?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performRespring];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performRespring {
    pid_t pid;
    const char *sbreload = "/var/jb/usr/bin/sbreload";
    if (access(sbreload, F_OK) != 0) {
        sbreload = "/usr/bin/sbreload";
    }
    
    if (access(sbreload, F_OK) == 0) {
        const char *argv[] = {sbreload, NULL};
        posix_spawn(&pid, sbreload, NULL, NULL, (char *const *)argv, environ);
    } else {
        const char *killall = "/var/jb/usr/bin/killall";
        if (access(killall, F_OK) != 0) {
            killall = "/usr/bin/killall";
        }
        const char *argv[] = {killall, "-9", "SpringBoard", NULL};
        posix_spawn(&pid, killall, NULL, NULL, (char *const *)argv, environ);
    }
}

- (void)resetDefaults {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset Defaults"
                                                                   message:@"Reset all DePuke preferences to their factory defaults?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSString *path = DePukePreferencePath();
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR(DEPUKE_RELOAD_NOTIFICATION),
            NULL,
            NULL,
            true
        );
        
        [self reloadSpecifiers];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end

#pragma mark - DePukeHeaderView

@implementation DePukeHeaderView

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DePukeHeaderView" specifier:specifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 180)];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // Logo ImageView
        UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake((containerView.frame.size.width - 64) / 2.0, 16, 64, 64)];
        logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        logoView.contentMode = UIViewContentModeScaleAspectFit;
        logoView.layer.cornerRadius = 14.0;
        if (@available(iOS 13.0, *)) {
            logoView.layer.cornerCurve = kCACornerCurveContinuous;
        }
        logoView.layer.masksToBounds = YES;
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *logoImg = [UIImage imageNamed:@"logo" inBundle:bundle compatibleWithTraitCollection:nil];
        if (!logoImg) {
            NSString *logoPath = [bundle pathForResource:@"logo@3x" ofType:@"png"] ?: [bundle pathForResource:@"logo" ofType:@"png"];
            if (logoPath) {
                logoImg = [UIImage imageWithContentsOfFile:logoPath];
            }
        }
        logoView.image = logoImg;
        [containerView addSubview:logoView];
        
        // Title Label
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 88, containerView.frame.size.width, 36)];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleLabel.text = @"DePuke";
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        titleLabel.textColor = [UIColor labelColor];
        [containerView addSubview:titleLabel];
        
        // Subtitle Label
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 126, containerView.frame.size.width, 22)];
        subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        subtitleLabel.text = @"Vehicle Motion Cues Backport";
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        subtitleLabel.textColor = [UIColor secondaryLabelColor];
        [containerView addSubview:subtitleLabel];
        
        // Animated Cue Dot Indicator preview
        UIView *dotsRow = [[UIView alloc] initWithFrame:CGRectMake((containerView.frame.size.width - 80) / 2.0, 154, 80, 8)];
        dotsRow.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        for (int i = 0; i < 5; i++) {
            UIView *miniDot = [[UIView alloc] initWithFrame:CGRectMake(i * 18, 1, 6, 6)];
            miniDot.layer.cornerRadius = 3.0;
            miniDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.60 blue:1.0 alpha:0.8];
            [dotsRow addSubview:miniDot];
        }
        [containerView addSubview:dotsRow];
        
        [self.contentView addSubview:containerView];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 180.0;
}

@end

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

@interface DePukeHeaderView ()
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *dotsRow;
@end

@implementation DePukeHeaderView

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DePukeHeaderView" specifier:specifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 14.0, *)) {
            self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
        
        // Logo ImageView
        _logoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64.0, 64.0)];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        _logoView.layer.cornerRadius = 14.0;
        if (@available(iOS 13.0, *)) {
            _logoView.layer.cornerCurve = kCACornerCurveContinuous;
        }
        _logoView.layer.masksToBounds = YES;
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *logoImg = [UIImage imageNamed:@"logo" inBundle:bundle compatibleWithTraitCollection:nil];
        if (!logoImg) {
            NSString *logoPath = [bundle pathForResource:@"logo@3x" ofType:@"png"] ?: [bundle pathForResource:@"logo" ofType:@"png"];
            if (logoPath) {
                logoImg = [UIImage imageWithContentsOfFile:logoPath];
            }
        }
        _logoView.image = logoImg;
        [self.contentView addSubview:_logoView];
        
        // Title Label
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"DePuke";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        _titleLabel.textColor = [UIColor labelColor];
        [self.contentView addSubview:_titleLabel];
        
        // Subtitle Label
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.text = @"Vehicle Motion Cues Backport";
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _subtitleLabel.textColor = [UIColor secondaryLabelColor];
        [self.contentView addSubview:_subtitleLabel];
        
        // Animated Cue Dot Indicator preview
        _dotsRow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80.0, 8.0)];
        for (int i = 0; i < 5; i++) {
            UIView *miniDot = [[UIView alloc] initWithFrame:CGRectMake(i * 18, 1, 6, 6)];
            miniDot.layer.cornerRadius = 3.0;
            miniDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.60 blue:1.0 alpha:0.8];
            [_dotsRow addSubview:miniDot];
        }
        [self.contentView addSubview:_dotsRow];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    if (@available(iOS 14.0, *)) {
        self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
    }
    
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat midX = width / 2.0;
    
    _logoView.frame = CGRectMake(midX - 32.0, 16.0, 64.0, 64.0);
    _titleLabel.frame = CGRectMake(0.0, 88.0, width, 36.0);
    _subtitleLabel.frame = CGRectMake(0.0, 126.0, width, 22.0);
    _dotsRow.frame = CGRectMake(midX - 40.0, 154.0, 80.0, 8.0);
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 180.0;
}

@end

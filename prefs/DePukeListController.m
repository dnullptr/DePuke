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
@property (nonatomic, strong) UIImageView *headerLogoView;
@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UILabel *headerSubtitleLabel;
@property (nonatomic, strong) UIView *headerDotsRow;
@end

@implementation DePukeHeaderView

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        // Logo ImageView
        _headerLogoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64.0, 64.0)];
        _headerLogoView.contentMode = UIViewContentModeScaleAspectFit;
        _headerLogoView.layer.cornerRadius = 14.0;
        if (@available(iOS 13.0, *)) {
            _headerLogoView.layer.cornerCurve = kCACornerCurveContinuous;
        }
        _headerLogoView.layer.masksToBounds = YES;
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *logoImg = [UIImage imageNamed:@"logo" inBundle:bundle compatibleWithTraitCollection:nil];
        if (!logoImg) {
            NSString *logoPath = [bundle pathForResource:@"logo@3x" ofType:@"png"] ?: [bundle pathForResource:@"logo" ofType:@"png"];
            if (logoPath) {
                logoImg = [UIImage imageWithContentsOfFile:logoPath];
            }
        }
        _headerLogoView.image = logoImg;
        [self addSubview:_headerLogoView];
        
        // Title Label
        _headerTitleLabel = [[UILabel alloc] init];
        _headerTitleLabel.text = @"DePuke";
        _headerTitleLabel.textAlignment = NSTextAlignmentCenter;
        _headerTitleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        _headerTitleLabel.textColor = [UIColor labelColor];
        [self addSubview:_headerTitleLabel];
        
        // Subtitle Label
        _headerSubtitleLabel = [[UILabel alloc] init];
        _headerSubtitleLabel.text = @"Vehicle Motion Cues Backport";
        _headerSubtitleLabel.textAlignment = NSTextAlignmentCenter;
        _headerSubtitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _headerSubtitleLabel.textColor = [UIColor secondaryLabelColor];
        [self addSubview:_headerSubtitleLabel];
        
        // Animated Cue Dot Indicator preview
        _headerDotsRow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80.0, 8.0)];
        for (int i = 0; i < 5; i++) {
            UIView *miniDot = [[UIView alloc] initWithFrame:CGRectMake(i * 18, 1, 6, 6)];
            miniDot.layer.cornerRadius = 3.0;
            miniDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.60 blue:1.0 alpha:0.8];
            [_headerDotsRow addSubview:miniDot];
        }
        [self addSubview:_headerDotsRow];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.bounds.size.width;
    if (width <= 0) return;
    CGFloat midX = width / 2.0;
    
    _headerLogoView.frame = CGRectMake(midX - 32.0, 16.0, 64.0, 64.0);
    _headerTitleLabel.frame = CGRectMake(0.0, 88.0, width, 36.0);
    _headerSubtitleLabel.frame = CGRectMake(0.0, 126.0, width, 22.0);
    _headerDotsRow.frame = CGRectMake(midX - 40.0, 154.0, 80.0, 8.0);
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 180.0;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView {
    return 180.0;
}

@end

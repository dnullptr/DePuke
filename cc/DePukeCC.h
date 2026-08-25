#pragma once

#import <UIKit/UIKit.h>

@protocol CCUIContentModule <NSObject>
@end

@interface CCUIToggleModule : NSObject <CCUIContentModule>
@property (nonatomic, readonly) UIViewController *contentViewController;
- (void)setSelected:(BOOL)selected;
- (BOOL)isSelected;
- (void)refreshState;
- (UIImage *)iconGlyph;
- (UIImage *)selectedIconGlyph;
- (UIColor *)selectedColor;
@end

@interface DePukeCC : CCUIToggleModule
@end

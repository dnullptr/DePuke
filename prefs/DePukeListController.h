#pragma once

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>

@protocol PSHeaderFooterView
- (instancetype)initWithSpecifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView;
@end

@interface DePukeListController : PSListController
- (void)respring;
- (void)resetDefaults;
@end

@interface DePukeHeaderView : UIView <PSHeaderFooterView>
@end

#pragma once

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>

@interface DePukeListController : PSListController
- (void)respring;
- (void)resetDefaults;
@end

@interface DePukeHeaderView : PSTableCell
@end

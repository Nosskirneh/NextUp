#import <Preferences/Preferences.h>
#import "../SettingsKeys.h"

#define NextUpColor [UIColor colorWithRed:0.00 green:0.65 blue:1.00 alpha:1.0] // #00A5FF

#define kPostNotification @"PostNotification"
#define kIconImage @"iconImage"
#define kKey @"key"
#define kID @"id"
#define kDefault @"default"
#define kCell @"cell"

@interface NUSettingsListController : PSListController {
    UIWindow *settingsView;
}
- (void)setEnabled:(BOOL)enabled forSpecifier:(PSSpecifier *)specifier;
- (void)setEnabled:(BOOL)enabled forSpecifiersAfterSpecifier:(PSSpecifier *)specifier;
- (void)setEnabled:(BOOL)enabled forSpecifiersAfterSpecifier:(PSSpecifier *)specifier
                                         excludedIdentifiers:(NSSet *)excludedIdentifiers;
- (void)setEnabled:(BOOL)enabled forSpecifiersInGroupID:(NSString *)groupID;
- (void)presentOKAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)presentAlertWithTitle:(NSString *)title
                      message:(NSString *)message
                      actions:(NSArray<UIAlertAction *> *)actions;
@end
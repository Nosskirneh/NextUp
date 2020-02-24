#import "NUSettingsListController.h"
#import <Preferences/Preferences.h>
#import <UIKit/UITableViewLabel.h>
#import "../DRMOptions.mm"
#import "../../DRM/PFStatusBarAlert/PFStatusBarAlert.h"
#import <spawn.h>
#import <notify.h>
#import "../../TwitterStuff/Prompt.h"
#import "../SettingsKeys.h"

#define kPostNotification @"PostNotification"

@interface NextUpRootListController : NUSettingsListController <PFStatusBarAlertDelegate, DRMDelegate>
@property (nonatomic, strong) PFStatusBarAlert *statusAlert;
@property (nonatomic, weak) UIAlertAction *okAction;
@property (nonatomic, weak) NSString *okRegex;
@property (nonatomic, strong) UIAlertController *giveawayAlertController;
@end

@implementation NextUpRootListController

- (id)init {
    if (self == [super init]) {
        UIBarButtonItem *respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring"
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(respring)];
        self.navigationItem.rightBarButtonItem = respringButton;
    }

    return self;
}

- (NSArray *)specifiers {
    if (!_specifiers)
        _specifiers = [self loadSpecifiersFromPlistName:@"NextUp" target:self];

    for (PSSpecifier *spec in _specifiers) {
        if ([spec.identifier isEqualToString:@"Music"] || [spec.identifier isEqualToString:@"Mail"]) {
            NSString *imageName = [NSString stringWithFormat:@"%@.png", spec.identifier];
            UIImage *image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleWithPath:preferencesFrameworkPath]];
            if (image)
                [spec setProperty:image forKey:kIconImage];
        } else if ([[specifier propertyForKey:kKey] isEqualToString:kHideArtwork] &&
                   [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
            [specifier setProperty:@(NO) forKey:@"enabled"];
        }
    }

    // Add license specifier
    NSMutableArray *mspecs = (NSMutableArray *)[_specifiers mutableCopy];
    _specifiers = addDRMSpecifiers(mspecs, self, licensePath$bs(), kPrefPath,
                                   package$bs(), licenseFooterText$bs(), trialFooterText$bs());

    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    id value = [super readPreferenceValue:specifier];

    NSString *key = [specifier propertyForKey:kKey];
    if ([key isEqualToString:kLockscreen])
        [self enableLockscreenSpecifiers:[value boolValue]];

    return value;
}

- (void)preferenceValueChanged:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:kKey];
    if ([key isEqualToString:kLockscreen])
        [self enableLockscreenSpecifiers:[value boolValue]];
}

- (void)enableLockscreenSpecifiers:(BOOL)enabled {
    [self setEnabled:enabled forSpecifier:[self specifierForID:kHideXButtons]];
    [self setEnabled:enabled forSpecifier:[self specifierForID:kHideHomeBar]];
    [self setEnabled:enabled forSpecifier:[self specifierForID:kSlimmedLSMode]];
}

- (void)loadView {
    [super loadView];
    presentFollowAlert(kPrefPath, self);
}

- (void)activate {
    activate(licensePath$bs(), package$bs(), self);
}

- (BOOL)textField:(UITextField *)textField
        shouldChangeCharactersInRange:(NSRange)range
        replacementString:(NSString *)string {
    [self textFieldChanged:textField];
    return YES;
}

- (void)textFieldChanged:(UITextField *)textField {
    determineUnlockOKButton(textField, self);
}

- (void)trial {
    trial(licensePath$bs(), package$bs(), self);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.statusAlert) {
        self.statusAlert = [[PFStatusBarAlert alloc] initWithMessage:nil
                                                        notification:nil
                                                              action:@selector(respring)
                                                              target:self];
        self.statusAlert.backgroundColor = [UIColor colorWithHue:0.590
                                                      saturation:1
                                                      brightness:1
                                                           alpha:0.9];
        self.statusAlert.textColor = [UIColor whiteColor];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self reloadSpecifiers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.statusAlert)
        [self.statusAlert hideOverlay];
}

- (void)sendEmail {
    openURL([NSURL URLWithString:@"mailto:andreaskhenriksson@gmail.com?subject=NextUp%202"]);
}

- (void)followTwitter {
    openTwitter();
}

- (void)purchase {
    fetchPrice(package$bs(), self, ^(const NSString *respondingServer,
                                     const NSString *price,
                                     const NSString *URL) {
        redirectToCheckout(respondingServer, URL, self);
    });
}

- (void)myTweaks {
    openURL([NSURL URLWithString:@"https://henrikssonbrothers.com/cydia/repo/packages.html"]);
}

- (void)troubleshoot {
    openURL([NSURL URLWithString:@"https://github.com/Nosskirneh/NextUp-Public/blob/master/README.md#troubleshooting--faq"]);
}

- (void)safariViewControllerDidFinish:(id)arg1 {
    safariViewControllerDidFinish(self);
}

@end


// Colorful UISwitches
@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier;
@end

@interface NextUpSwitchTableCell : PSSwitchTableCell
@end

@implementation NextUpSwitchTableCell

- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];
    if (self)
        [((UISwitch *)[self control]) setOnTintColor:NextUpColor];
    return self;
}

@end


// Header
@interface NextUpSettingsHeaderCell : PSTableCell {
    UILabel *_label;
}
@end

@implementation NextUpSettingsHeaderCell

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"headerCell" specifier:specifier];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:[self frame]];
        [_label setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_label setAdjustsFontSizeToFitWidth:YES];
        [_label setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48]];
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"NextUp"];
        
        [_label setAttributedText:attributedString];
        [_label setTextAlignment:NSTextAlignmentCenter];
        [_label setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:_label];
        [self setBackgroundColor:[UIColor clearColor]];
        
        // Setup constraints
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:_label
                                                                          attribute:NSLayoutAttributeLeft
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self
                                                                          attribute:NSLayoutAttributeLeft
                                                                         multiplier:1.0
                                                                           constant:0.0];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:_label
                                                                           attribute:NSLayoutAttributeRight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeRight
                                                                          multiplier:1.0
                                                                            constant:0.0];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_label
                                                                            attribute:NSLayoutAttributeBottom
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:0.0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:_label
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:0.0];
        [self addConstraints:@[leftConstraint, rightConstraint, bottomConstraint, topConstraint]];
    }
    return self;
}

// Return a custom cell height.
- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 140.f;
}

@end


@interface NextUpColorButtonCell : PSTableCell
@end


@implementation NextUpColorButtonCell

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.textLabel setTextColor:NextUpColor];
}

@end

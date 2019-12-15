#import <Preferences/Preferences.h>
#import <UIKit/UITableViewLabel.h>
#import "../Common.h"
#import "../DRMOptions.mm"
#import "../../DRM/PFStatusBarAlert/PFStatusBarAlert.h"
#import <spawn.h>
#import <notify.h>
#import "../../TwitterStuff/Prompt.h"
#import "../SettingsKeys.h"

#define NextUpColor [UIColor colorWithRed:0.00 green:0.65 blue:1.00 alpha:1.0] // #00A5FF
#define kPostNotification @"PostNotification"

@interface NextUpRootListController : PSListController <PFStatusBarAlertDelegate, DRMDelegate> {
    UIWindow *settingsView;
}
@property (nonatomic, strong) PFStatusBarAlert *statusAlert;
@property (nonatomic, weak) UIAlertAction *okAction;
@property (nonatomic, weak) NSString *okRegex;
@property (nonatomic, strong) UIAlertController *giveawayAlertController;
@end

#define kIconImage @"iconImage"
#define kKey @"key"
#define kDefault @"default"

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


    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        for (PSSpecifier *specifier in _specifiers) {
            if ([[specifier propertyForKey:kKey] isEqualToString:kHideArtwork])
                [specifier setProperty:@(NO) forKey:@"enabled"];
        }
    }
    // Add license specifier
    NSMutableArray *mspecs = (NSMutableArray *)[_specifiers mutableCopy];
    _specifiers = addDRMSpecifiers(mspecs, self, licensePath$bs(), kPrefPath,
                                   package$bs(), licenseFooterText$bs(), trialFooterText$bs());

    return _specifiers;
}

- (void)loadView {
    [super loadView];
    presentFollowAlert(kPrefPath, self);
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    NSString *key = [specifier propertyForKey:kKey];

    if (preferences[key])
        return preferences[key];

    return specifier.properties[kDefault];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (!preferences) preferences = [NSMutableDictionary new];
    NSString *key = [specifier propertyForKey:kKey];

    [preferences setObject:value forKey:key];
    [preferences writeToFile:kPrefPath atomically:YES];
    
    NSString *notificationString = specifier.properties[kPostNotification];
    if (notificationString)
        notify_post([notificationString UTF8String]);
}

- (void)respring {
    respring(NO);
}

- (void)activate {
    presentMultiTweakQuestionWithInfo(self, @[[UIAlertAction actionWithTitle:OBFS_NSSTR(nextUpDisplayName$bs())
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
        activateWithUpgradePackagePromptEmail(licensePath$bs(), package$bs(), nextup$bs(), self);
    }],
    [UIAlertAction actionWithTitle:OBFS_NSSTR(nextUp2DisplayName$bs())
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
        activate(licensePath$bs(), package$bs(), self);
    }]], choosingTheWrongProductWillNOTWork$bs());
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
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
        self.statusAlert.backgroundColor = [UIColor colorWithHue:0.590 saturation:1 brightness:1 alpha:0.9];
        self.statusAlert.textColor = [UIColor whiteColor];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Tint
    settingsView = [[UIApplication sharedApplication] keyWindow];
    settingsView.tintColor = NextUpColor;

    [self reloadSpecifiers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    settingsView = [[UIApplication sharedApplication] keyWindow];
    settingsView.tintColor = nil;

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
    fetchPrice(package$bs(), self, ^(const NSString *respondingServer, const NSString *price, const NSString *URL) {
        redirectToCheckout(respondingServer, URL, self);
    });
}

- (void)myTweaks {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://henrikssonbrothers.com/cydia/repo/packages.html"]];
}

- (void)troubleshoot {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/Nosskirneh/NextUp-Public/blob/master/README.md#troubleshooting--faq"]];
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
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"NextUp 2"];
        
        [_label setAttributedText:attributedString];
        [_label setTextAlignment:NSTextAlignmentCenter];
        [_label setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:_label];
        [self setBackgroundColor:[UIColor clearColor]];
        
        // Setup constraints
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        [self addConstraints:[NSArray arrayWithObjects:leftConstraint, rightConstraint, bottomConstraint, topConstraint, nil]];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    // Return a custom cell height.
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

#import <Preferences/Preferences.h>
#import <UIKit/UITableViewLabel.h>
#import "../Common.h"
#import "../DRMOptions.mm"
#import "../../DRM/PFStatusBarAlert/PFStatusBarAlert.h"
#import <spawn.h>
#import <PayPalMobile/PayPalMobile.h>

#define NextUpColor [UIColor colorWithRed:0.00 green:0.65 blue:1.00 alpha:1.0] // #00A5FF
#define preferencesFrameworkPath @"/System/Library/PrivateFrameworks/Preferences.framework"
#define kPostNotification @"PostNotification"

@interface NextUpRootListController : PSListController <PFStatusBarAlertDelegate, PayPalPaymentDelegate> {
    UIWindow *settingsView;
}
@property (nonatomic, strong) PFStatusBarAlert *statusAlert;

@property (nonatomic, strong, readwrite) UIView *successView;
@property (nonatomic, strong, readwrite) PayPalConfiguration *payPalConfig;
@property (nonatomic, strong, readwrite) NSString *resultText;
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
                                                                          action:@selector(respring:)];
        self.navigationItem.rightBarButtonItem = respringButton;

        _payPalConfig = initPayPal();
        self.successView.hidden = YES;
    }

    return self;
}

- (NSArray *)specifiers {
    if (!_specifiers)
        _specifiers = [self loadSpecifiersFromPlistName:@"NextUp" target:self];

    for (PSSpecifier *spec in _specifiers) {
        UIImage *image;
        if ([spec.identifier isEqualToString:@"Music"] || [spec.identifier isEqualToString:@"Mail"]) {
            NSString *imageName = [NSString stringWithFormat:@"%@.png", spec.identifier];
            image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleWithPath:preferencesFrameworkPath]];
        }

        if (image)
            [spec setProperty:image forKey:kIconImage];
    }

    // Add license specifier
    NSMutableArray *mspecs = (NSMutableArray *)[_specifiers mutableCopy];
    _specifiers = addDRMSpecifiers(mspecs, self, licensePath$bs(), package$bs(), licenseFooterText$bs(), trialFooterText$bs());

    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    NSString *key = [specifier propertyForKey:kKey];

    if (preferences[key])
        return preferences[key];

    return specifier.properties[kDefault];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
    if (!preferences) preferences = [[NSMutableDictionary alloc] init];
    NSString *key = [specifier propertyForKey:kKey];

    [preferences setObject:value forKey:key];
    [preferences writeToFile:kPrefPath atomically:YES];
    
    if (specifier.properties[kPostNotification]) {
        CFStringRef post = (CFStringRef)CFBridgingRetain(specifier.properties[kPostNotification]);
        notify(post);
    }
}

- (void)respring:(id)sender {
    pid_t pid;
    const char *args[] = {"killall", "-9", "backboardd", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
}

- (void)activate {
    activate(licensePath$bs(), package$bs(), self);
}

- (void)paypalEmailTextFieldChanged:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UIAlertAction *okAction = alertController.actions.lastObject;
        okAction.enabled = [self validateEmail:textField.text];
    }
}

- (BOOL)validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

- (void)trial {
    trial(licensePath$bs(), package$bs(), self);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.statusAlert) {
        self.statusAlert = [[PFStatusBarAlert alloc] initWithMessage:nil
                                                        notification:nil
                                                              action:@selector(respring:)
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:andreaskhenriksson@gmail.com?subject=NextUp"]];
}

#pragma mark PayPal

- (void)purchase {
    self.resultText = nil;

    fetchPrice(package$bs(), self, ^(NSString *price) {
        showPaymentViewController(packageShown$bs(), OBFS_UTF8(price), SKU$bs(), self.payPalConfig, self);
    });
}

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    self.resultText = [completedPayment description];
    [self showSuccess];

    [self dismissViewControllerAnimated:YES completion:^{
        storePaymentAndActivate(completedPayment, licensePath$bs(), package$bs(), self);
    }];
}

- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    self.resultText = nil;
    self.successView.hidden = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showSuccess {
    self.successView.hidden = NO;
    self.successView.alpha = 1.0f;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:2.0];
    self.successView.alpha = 0.0f;
    [UIView commitAnimations];
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

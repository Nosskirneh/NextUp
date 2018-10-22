#import <Preferences/Preferences.h>
#import <UIKit/UITableViewLabel.h>
#import "../Common.h"
#import "../DRMOptions.mm"
#import "../../DRM/PFStatusBarAlert/PFStatusBarAlert.h"
#import <spawn.h>

#define NextUpColor [UIColor redColor]
#define preferencesFrameworkPath @"/System/Library/PrivateFrameworks/Preferences.framework"

@interface NextUpRootListController : PSListController <PFStatusBarAlertDelegate> {
    UIWindow *settingsView;
}
@property (nonatomic, strong) PFStatusBarAlert *statusAlert;
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
    _specifiers = addLicenseSpecifier(mspecs, self, licensePath$bs(), package$bs(), linkDeviceText$bs());

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
}

- (void)respring:(id)sender {
    pid_t pid;
    const char *args[] = {"killall", "-9", "backboardd", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
}

- (void)activate {
    rnalloc(licensePath$bs(), package$bs(), version$bs(), self);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.statusAlert) {
        self.statusAlert = [[PFStatusBarAlert alloc] initWithMessage:@"NextUp – Tap to Respring"
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

#import "Headers.h"
#import "Common.h"

#define DIGITAL_TOUCH_BUNDLE [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/DigitalTouchShared.framework"]

@interface NUSkipButton : UIButton
@end

%subclass NUSkipButton : UIButton

- (void)setUserInteractionEnabled:(BOOL)enabled {
    %orig(YES);
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.95);
}

%end

@interface NULabel : UILabel
@end

%subclass NULabel : UILabel

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.75);
}

%end

@interface NextUpMediaHeaderView : MediaControlsHeaderView
@property (nonatomic, retain) NUSkipButton *routingButton;
@end

%subclass NextUpMediaHeaderView : MediaControlsHeaderView

// Override routing button
%property (nonatomic, retain) NUSkipButton *routingButton;
%property (nonatomic, retain) NULabel *primaryLabel;
%property (nonatomic, retain) NULabel *secondaryLabel;

- (id)initWithFrame:(CGRect)arg1 {
    NextUpMediaHeaderView *orig = %orig;

    NUSkipButton *skipButton = [%c(NUSkipButton) buttonWithType:UIButtonTypeSystem];
    UIImage *image = [UIImage imageNamed:@"Cancel.png" inBundle:DIGITAL_TOUCH_BUNDLE];
    [skipButton setImage:image forState:UIControlStateNormal];
    orig.routingButton = skipButton;
    [orig addSubview:orig.routingButton];

    orig.primaryLabel = [[%c(NULabel) alloc] initWithFrame:CGRectZero];
    orig.secondaryLabel = [[%c(NULabel) alloc] initWithFrame:CGRectZero];
    [orig.primaryMarqueeView.contentView addSubview:orig.primaryLabel];
    [orig.secondaryMarqueeView.contentView addSubview:orig.secondaryLabel];

    return orig;
}

- (void)layoutSubviews {
    %orig;

    CGRect frame = self.primaryMarqueeView.frame;
    float maxWidth = self.routingButton.frame.origin.x - self.artworkView.frame.origin.x - self.artworkView.frame.size.width - 15;
    frame.size.width = fmin(frame.size.width, maxWidth);
    self.primaryMarqueeView.frame = frame;
}

%end

@implementation NextUpViewController

@dynamic view;

- (id)init {
    if (self == [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateLabels)
                                                     name:kUpdateLabels
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showNextUp)
                                                     name:kShowNextUp
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(hideNextUp)
                                                     name:kHideNextUp
                                                   object:nil];

        self.hapticGenerator = [[%c(UIImpactFeedbackGenerator) alloc] initWithStyle:UIImpactFeedbackStyleMedium];

        if (%c(NoctisSystemController)) {
            NSDictionary *noctisPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laughingquoll.noctisxiprefs.settings.plist"];
            self.noctisEnabled = !noctisPrefs || [noctisPrefs[@"enableMedia"] boolValue];
        }
    }

    return self;
}

- (void)showNextUp {
    self.view.alpha = 1.0f;
}

- (void)hideNextUp {
    self.view.alpha = 0.0f;
}

- (void)loadView {
    [super loadView];

    CGSize size = [self preferredContentSize];
    self.view = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.view.axis = UILayoutConstraintAxisVertical;
    self.view.spacing = 8;

    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];

    self.mediaView = [[%c(NextUpMediaHeaderView) alloc] initWithFrame:CGRectZero];
    if (!self.controlCenter)
        _mediaView.style = self.noctisEnabled ? 2 : 3; // lockscreen - else 0 (automatically)

    if ([_mediaView respondsToSelector:@selector(setShouldEnableMarquee:)])
        [_mediaView setShouldEnableMarquee:YES];
    else if ([_mediaView respondsToSelector:@selector(setMarqueeEnabled:)])
        [_mediaView setMarqueeEnabled:YES];

    _mediaView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_mediaView];

    [_mediaView.routingButton addTarget:self 
                                 action:@selector(skipTrack:)
                       forControlEvents:UIControlEventTouchUpInside];

    self.headerLabel = [[UILabel alloc] init];
    self.headerLabel.backgroundColor = UIColor.clearColor;
    self.headerLabel.textAlignment = NSTextAlignmentLeft;
    self.headerLabel.textColor = self.noctisEnabled ? UIColor.whiteColor : UIColor.blackColor;
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.alpha = 0.64;
    self.headerLabel.text = @"Next up";
    [self.contentView addSubview:self.headerLabel];

    int horizontalPadding = -8;
    if (self.controlCenter) {
        self.headerLabel.hidden = YES;

        horizontalPadding = 0;
    }

    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.headerLabel.bottomAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20].active = YES;
    [self.headerLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:15].active = YES;

    // Media view constraints
    [_mediaView.topAnchor constraintEqualToAnchor:self.headerLabel.bottomAnchor].active = YES;
    [_mediaView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
    [_mediaView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:horizontalPadding].active = YES;
    [_mediaView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-horizontalPadding].active = YES;

    [self.view addArrangedSubview:self.contentView];

    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.contentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.contentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;

    [self updateLabels];
}

- (void)skipTrack:(UIButton *)sender {
    [self.hapticGenerator impactOccurred];

    if (isAppCurrentMediaApp(kSpotifyBundleID))
        notify(kSPTSkipNext);
    else if (isAppCurrentMediaApp(kMusicBundleID))
        notify(kAPMSkipNext);
    else if (isAppCurrentMediaApp(kDeezerBundleID))
        notify(kDZRSkipNext);
}

- (void)updateLabels {
    NSDictionary *metadata = _metadataSaver.metadata;
    if (metadata) {
        _mediaView.primaryString = metadata[@"trackTitle"];
        _mediaView.secondaryString = metadata[@"artistTitle"];

        _mediaView.artworkView.image = [UIImage imageWithData:metadata[@"artwork"]];
    } else {
        _mediaView.primaryString = @"Loading...";
        _mediaView.secondaryString = nil;
        _mediaView.artworkView.image = nil;
    }
}

// Note that this is called manually
- (void)viewDidAppear:(BOOL)arg {
    [super viewDidAppear:arg];

    _mediaView.primaryMarqueeView.marqueeEnabled = YES;
    _mediaView.secondaryMarqueeView.marqueeEnabled = YES;
}

@end

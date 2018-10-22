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

@interface NextUpMediaHeaderView : MediaControlsHeaderView
@property (nonatomic, retain) NUSkipButton *routingButton;
@end

%subclass NextUpMediaHeaderView : MediaControlsHeaderView

// Override routing button
%property (nonatomic, retain) NUSkipButton *routingButton;

- (id)initWithFrame:(CGRect)arg1 {
    NextUpMediaHeaderView *orig = %orig;

    NUSkipButton *skipButton = [[%c(NUSkipButton) alloc] initWithFrame:CGRectZero];
    UIImage *image = [UIImage imageNamed:@"Cancel.png" inBundle:DIGITAL_TOUCH_BUNDLE];
    [skipButton setImage:image forState:UIControlStateNormal];
    orig.routingButton = skipButton;

    [orig addSubview:orig.routingButton];
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
    if (self == [super init])
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateLabels)
                                                     name:kUpdateLabels
                                                   object:nil];

    return self;
}

- (void)loadView {
    [super loadView];

    CGSize size = [self preferredContentSize];
    self.view = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.view.axis = UILayoutConstraintAxisVertical;
    self.view.spacing = 8;

    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];

    self.mediaView = [[%c(NextUpMediaHeaderView) alloc] initWithFrame:CGRectZero];
    _mediaView.style = 3;
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
    self.headerLabel.backgroundColor = [UIColor clearColor];
    self.headerLabel.textAlignment = NSTextAlignmentLeft;
    self.headerLabel.textColor = [UIColor blackColor];
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.alpha = 0.64;
    self.headerLabel.text = @"Next up";
    [self.contentView addSubview:self.headerLabel];

    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.headerLabel.bottomAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20].active = YES;
    [self.headerLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:15].active = YES;

    // Media view constraints
    [_mediaView.topAnchor constraintEqualToAnchor:self.headerLabel.bottomAnchor].active = YES;
    [_mediaView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
    [_mediaView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:-8].active = YES;
    [_mediaView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:8].active = YES;

    [self.view addArrangedSubview:self.contentView];

    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.contentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.contentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;

    [self updateLabels];
}

- (void)skipTrack:(UIButton *)sender {
    HBLogDebug(@"skipTrack");
    if (isAppCurrentMediaApp(kSpotifyBundleID))
        notify(kSPTSkipNext);
    else if (isAppCurrentMediaApp(kMusicBundleID))
        notify(kAPMSkipNext);
    else if (isAppCurrentMediaApp(kDeezerBundleID))
        notify(kDZRSkipNext);
}

- (void)updateLabels {
    // NSArray *metadatas = @[
    // @{
    //     @"artistTitle" : @"Sunfly Karaoke",
    //     @"trackTitle" : @"What Have I Done to Deserve This in the Style of Dusty Springfield & Pet Shop Boys"
    // }];

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

// Note that this is called manually!
- (void)viewDidAppear:(BOOL)arg {
    [super viewDidAppear:arg];

    _mediaView.primaryMarqueeView.marqueeEnabled = YES;
    _mediaView.secondaryMarqueeView.marqueeEnabled = YES;
}

@end

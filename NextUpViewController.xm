#import "Headers.h"
#import "Common.h"

@implementation NextUpViewController {
    UIColor *_textColor;
    CGFloat _textAlpha;
    UIColor *_skipBackgroundColor;
}

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

        _textAlpha = 0.63f;
        _textColor = UIColor.blackColor;
        _skipBackgroundColor = [UIColor.grayColor colorWithAlphaComponent:0.5];

        if (!_manager.preferences[kHapticFeedbackSkip] || [_manager.preferences[kHapticFeedbackSkip] boolValue])
            self.hapticGenerator = [[%c(UIImpactFeedbackGenerator) alloc] initWithStyle:UIImpactFeedbackStyleMedium];

        self.bundle = [NSBundle bundleWithPath:@"/Library/Application Support/NextUp.bundle"];
    }

    return self;
}

- (void)showNextUp {
    self.view.alpha = 1.0f;
}

- (void)hideNextUp {
    self.view.alpha = 0.0f;
}

- (void)setStyle:(long long)style {
    _style = style;

    self.mediaView.style = style;
}

- (void)loadView {
    [super loadView];

    CGSize size = [self preferredContentSize];
    self.view = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.view.axis = UILayoutConstraintAxisVertical;
    self.view.spacing = 8;

    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];

    self.mediaView = [[%c(NextUpMediaHeaderView) alloc] initWithFrame:CGRectZero];
    self.mediaView.style = self.style;
    self.mediaView.textAlpha = _textAlpha;
    [self.mediaView updateTextColor:_textColor];
    [self.mediaView updateSkipBackgroundColor:_skipBackgroundColor];

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
    self.headerLabel.textColor = _textColor;
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.alpha = 0.64;
    self.headerLabel.text = [self.bundle localizedStringForKey:@"NEXT_UP" value:nil table:nil];
    [self.contentView addSubview:self.headerLabel];

    int horizontalPadding = -8;
    if (self.controlCenter) {
        self.headerLabel.hidden = YES;

        horizontalPadding = 0;
    }

    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.headerLabel.bottomAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20].active = YES;
    // Left to Right language, such as Arabic
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft)
        [self.headerLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-15].active = YES;
    else
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
    if (self.hapticGenerator)
        [self.hapticGenerator impactOccurred];

    NSString *skipNext = [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kSkipNext, _manager.mediaApplication];
    notify(skipNext);

    [[%c(SBIdleTimerGlobalCoordinator) sharedInstance] resetIdleTimer];
}

- (void)updateLabels {
    NSDictionary *metadata = _manager.metadata;
    if (metadata) {
        _mediaView.primaryString = metadata[kTitle];
        _mediaView.secondaryString = metadata[kSubtitle];
        _mediaView.artworkView.image = [UIImage imageWithData:metadata[kArtwork]];
        _mediaView.routingButton.hidden = metadata[kSkipable] && ![metadata[kSkipable] boolValue];

        if ([_manager hideOnEmpty])
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
    } else {
        _mediaView.primaryString = @"No next track available";
        _mediaView.secondaryString = nil;
        _mediaView.artworkView.image = nil;
        _mediaView.routingButton.hidden = YES;

        if ([_manager hideOnEmpty])
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
    }
}

// Note that this is called manually
- (void)viewDidAppear:(BOOL)arg {
    [super viewDidAppear:arg];

    _mediaView.primaryMarqueeView.marqueeEnabled = YES;
    _mediaView.secondaryMarqueeView.marqueeEnabled = YES;
}

@end

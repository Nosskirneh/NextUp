#import "SettingsKeys.h"
#import "Headers.h"
#import "Common.h"
#import <notify.h>

@interface NextUpViewController ()
@property (nonatomic, retain) NSBundle *bundle;
@property (nonatomic, retain) UIImpactFeedbackGenerator *hapticGenerator;
@property (nonatomic, retain) UIStackView *view;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, weak) NextUpManager *manager;
@end

@implementation NextUpViewController {
    UIColor *_textColor;
    CGFloat _textAlpha;
    UIColor *_skipBackgroundColor;
}

@dynamic view;

- (id)initWithControlCenter:(BOOL)controlCenter
               defaultStyle:(long long)style {
    if (self == [super init]) {
        _controlCenter = controlCenter;
        _style = style;
        _manager = [NextUpManager sharedInstance];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(metadataChanged:)
                       name:kUpdateLabels
                     object:nil];

        [center addObserver:self
                   selector:@selector(showNextUp)
                       name:kShowNextUp
                     object:nil];

        [center addObserver:self
                   selector:@selector(hideNextUp)
                       name:kHideNextUp
                     object:nil];

        _textAlpha = 1.0f;
        _textColor = UIColor.whiteColor;
        if (!controlCenter && !_manager.flowEnabled) {
            if (@available(iOS 13, *)) {
                [center addObserver:self
                           selector:@selector(_traitCollectionDidChange)
                               name:@"_UIScreenDefaultTraitCollectionDidChangeNotification"
                             object:nil];

                if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight)
                    _textColor = UIColor.blackColor;
            }
        }

        [self _updateSkipBackgroundColor];

        if (_manager.hapticFeedbackSkip)
            self.hapticGenerator = [[%c(UIImpactFeedbackGenerator) alloc] initWithStyle:UIImpactFeedbackStyleMedium];

        self.bundle = [NSBundle bundleWithPath:@"/Library/Application Support/NextUp.bundle"];
    }

    return self;
}

- (void)_traitCollectionDidChange {
    if (self.overrideUserInterfaceStyle == UIUserInterfaceStyleUnspecified)
        [self _updateTextColorWithUserInterfaceStyle:[UIScreen mainScreen].traitCollection.userInterfaceStyle];
}

- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style {
    [super setOverrideUserInterfaceStyle:style];
    [self _updateTextColorWithUserInterfaceStyle:style];
}

- (void)_updateTextColorWithUserInterfaceStyle:(UIUserInterfaceStyle)style {
    _textColor = (style == UIUserInterfaceStyleLight) ? UIColor.blackColor : UIColor.whiteColor;
    [self _updateTextColor];
    [self _updateSkipBackgroundColor];
}

- (void)_updateSkipBackgroundColor {
    _skipBackgroundColor = [_textColor colorWithAlphaComponent:0.16];
    [self.mediaView updateSkipBackgroundColor:_skipBackgroundColor];
}

- (void)_updateTextColor {
    [self.mediaView setNewTextColor:_textColor];
    self.headerLabel.textColor = _textColor;
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

    self.mediaView = [[%c(NextUpMediaHeaderView) alloc] initWithFrame:CGRectZero controlCenter:_controlCenter];
    _mediaView.style = self.style;
    _mediaView.textAlpha = _textAlpha;
    [_mediaView setNewTextColor:_textColor];
    [_mediaView updateSkipBackgroundColor:_skipBackgroundColor];

    if ([_mediaView respondsToSelector:@selector(setShouldEnableMarquee:)])
        [_mediaView setShouldEnableMarquee:YES];
    else if ([_mediaView respondsToSelector:@selector(setMarqueeEnabled:)])
        [_mediaView setMarqueeEnabled:YES];

    _mediaView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_mediaView];

    [_mediaView.routingButton addTarget:self
                                 action:@selector(skipTrack:)
                       forControlEvents:UIControlEventTouchUpInside];

    int horizontalPadding = -8;
    NSLayoutYAxisAnchor *lowestTopAnchor = _contentView.topAnchor;
    int verticalConstant = 0;

    if (!_controlCenter && !_manager.slimmedLSMode) {
        self.headerLabel = [[UILabel alloc] init];
        _headerLabel.backgroundColor = UIColor.clearColor;
        _headerLabel.textAlignment = NSTextAlignmentLeft;
        _headerLabel.textColor = _textColor;
        _headerLabel.numberOfLines = 0;
        _headerLabel.alpha = 0.64;
        _headerLabel.text = [self.bundle localizedStringForKey:@"NEXT_UP" value:nil table:nil];
        [_contentView addSubview:_headerLabel];

        _headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_headerLabel.topAnchor constraintEqualToAnchor:_contentView.topAnchor].active = YES;
        [_headerLabel.bottomAnchor constraintEqualToAnchor:_contentView.topAnchor
                                                constant:20].active = YES;
        // Right to left language (RTL), such as Arabic
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft)
            [_headerLabel.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor
                                                     constant:-15].active = YES;
        else
            [_headerLabel.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor
                                                    constant:15].active = YES;

        lowestTopAnchor = _headerLabel.bottomAnchor;
    } else if (_controlCenter) {
        horizontalPadding = 0;
    } else {
        verticalConstant = -20;
    }

    // Media view constraints
    [NSLayoutConstraint activateConstraints:@[
        [_mediaView.topAnchor constraintEqualToAnchor:lowestTopAnchor constant:verticalConstant],
        [_mediaView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
        [_mediaView.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor constant:horizontalPadding],
        [_mediaView.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor constant:-horizontalPadding]
    ]];

    [self.view addArrangedSubview:_contentView];

    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_contentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [_contentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor]
    ]];

    [self updateLabels:_manager.metadata];
}

- (void)skipTrack:(UIButton *)sender {
    if (self.hapticGenerator)
        [self.hapticGenerator impactOccurred];

    NSString *skipNext = [NSString stringWithFormat:@"%@/%@/%@",
                          NEXTUP_IDENTIFIER, kSkipNext, _manager.mediaApplication];
    notify_post([skipNext UTF8String]);

    if (!_controlCenter) {
        [[%c(SBIdleTimerGlobalCoordinator) sharedInstance] resetIdleTimer];
    }
}

- (void)metadataChanged:(NSNotification *)notification {
    [self updateLabels:notification.object];
}

- (void)updateLabels:(NSDictionary *)metadata {
    if (metadata) {
        _mediaView.primaryString = metadata[kTitle];
        _mediaView.secondaryString = metadata[kSubtitle];
        _mediaView.artworkView.image = [UIImage imageWithData:metadata[kArtwork]];
        _mediaView.routingButton.hidden = metadata[kSkipable] && ![metadata[kSkipable] boolValue];
    } else {
        _mediaView.primaryString = @"No next track available";
        _mediaView.secondaryString = nil;
        _mediaView.artworkView.image = nil;
        _mediaView.routingButton.hidden = YES;
    }
}

// Needed in order to show on iOS 13.3+ lockscreen
- (BOOL)_canShowWhileLocked {
    return YES;
}

@end

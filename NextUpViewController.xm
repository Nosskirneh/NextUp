#import "SettingsKeys.h"
#import "Headers.h"
#import "Common.h"
#import <notify.h>

extern NextUpManager *manager;

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
        _manager = manager;

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

        _textAlpha = 0.63f;
        _textColor = UIColor.blackColor;
        _skipBackgroundColor = [UIColor.grayColor colorWithAlphaComponent:0.5];

        if (manager.hapticFeedbackSkip)
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

    if (!self.controlCenter && ![_manager slimmedLSMode]) {
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
    } else if (self.controlCenter) {
        horizontalPadding = 0;
    } else {
        verticalConstant = -20;
    }

    // Media view constraints
    [_mediaView.topAnchor constraintEqualToAnchor:lowestTopAnchor
                                         constant:verticalConstant].active = YES;
    [_mediaView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor].active = YES;
    [_mediaView.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor
                                          constant:horizontalPadding].active = YES;
    [_mediaView.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor
                                           constant:-horizontalPadding].active = YES;

    [self.view addArrangedSubview:_contentView];

    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [_contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [_contentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [_contentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;

    [self updateLabels:_manager.metadata];
}

- (void)skipTrack:(UIButton *)sender {
    if (self.hapticGenerator)
        [self.hapticGenerator impactOccurred];

    NSString *skipNext = [NSString stringWithFormat:@"%@/%@/%@",
                          NEXTUP_IDENTIFIER, kSkipNext, _manager.mediaApplication];
    notify_post([skipNext UTF8String]);

    [[%c(SBIdleTimerGlobalCoordinator) sharedInstance] resetIdleTimer];
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

@end

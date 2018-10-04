#import "Headers.h"


@implementation NextUpViewController

@dynamic view;

- (void)loadView {
    [super loadView];

    CGSize size = [self preferredContentSize];
    self.view = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.view.axis = UILayoutConstraintAxisVertical;
    self.view.spacing = 8;

    self.showsHeader = YES;

    // Header
    if (self.showsHeader) {
        SBUILegibilityLabel *headerLabel = [[%c(SBUILegibilityLabel) alloc] init];
        headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [%c(NCNotificationListSectionHeaderView) _labelFont];
        headerLabel.string = @"Next Up";

        self.headerView = [[UIView alloc] init];
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;

        [_headerView addSubview:headerLabel];
        [headerLabel.topAnchor constraintEqualToAnchor:_headerView.topAnchor].active = YES;
        [headerLabel.bottomAnchor constraintEqualToAnchor:_headerView.bottomAnchor].active = YES;
        [headerLabel.leftAnchor constraintEqualToAnchor:_headerView.leftAnchor constant:12].active = YES;
        [headerLabel.rightAnchor constraintEqualToAnchor:_headerView.rightAnchor constant:-12].active = YES;

        [self.view addArrangedSubview:_headerView];
        [_headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [_headerView.bottomAnchor constraintEqualToAnchor:self.view.topAnchor constant:45].active = YES;
        [_headerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [_headerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    }

    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    // Background
    if (self.background == 0) { // Light blur
        [self addBlurViewWithStyle:UIBlurEffectStyleLight];
    } else if (self.background == 1) { // Dark blur
        [self addBlurViewWithStyle:UIBlurEffectStyleDark];
    } else { // Vibrant Blur
        self.contentView.backgroundColor = UIColor.clearColor;
        self.blurView = [%c(MTMaterialView) materialViewWithRecipe:4 options:128];
        [self.contentView insertSubview:self.blurView atIndex:0];
    }
    // [_blurView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor constant:20].active = YES;
    // [_blurView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor].active = YES;
    // [_blurView.leftAnchor constraintEqualToAnchor:self.headerView.leftAnchor].active = YES;
    // [_blurView.rightAnchor constraintEqualToAnchor:self.headerView.rightAnchor].active = YES;


    self.mediaView = [[%c(MediaControlsHeaderView) alloc] initWithFrame:CGRectZero];
    if ([_mediaView respondsToSelector:@selector(setShouldEnableMarquee:)])
        [_mediaView setShouldEnableMarquee:YES];
    else if ([_mediaView respondsToSelector:@selector(setMarqueeEnabled:)])
        [_mediaView setMarqueeEnabled:YES];

    _mediaView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_mediaView];
    HBLogDebug(@"headerView: %@", self.headerView);
    // change this to blurview ?
    [_mediaView.topAnchor constraintEqualToAnchor:self.blurView.topAnchor constant:20].active = YES;
    [_mediaView.bottomAnchor constraintEqualToAnchor:self.blurView.bottomAnchor constant:-20].active = YES;
    [_mediaView.leftAnchor constraintEqualToAnchor:self.blurView.leftAnchor].active = YES;
    [_mediaView.rightAnchor constraintEqualToAnchor:self.blurView.rightAnchor].active = YES;

    [self.view addArrangedSubview:self.contentView];

    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor].active = YES;
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.contentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.contentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    HBLogDebug(@"done");
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];


    // NSArray *metadatas = @[
    // @{
    //     @"artistTitle" : @"Sunfly Karaoke",
    //     @"trackTitle" : @"What Have I Done to Deserve This in the Style of Dusty Springfield & Pet Shop Boys"
    // }];

    NSArray *metadatas = _metadataSaver.metadatas;
    if (metadatas.count > 0) {

        _mediaView.primaryString = metadatas[0][@"trackTitle"];
        _mediaView.secondaryString = metadatas[0][@"artistTitle"];
        _mediaView.primaryMarqueeView.marqueeEnabled = YES;
        _mediaView.style = 2;

        _mediaView.artworkView.image = [UIImage imageWithData:metadatas[0][@"artwork"]];
    }
}

- (void)updatePreferredContentSize {
    CGFloat height = 105;
    CGRect frame = CGRectMake(0, 0, self.containerSize.width, height);
    self.blurView.frame = frame;

    // if (self.showsHeader) // If header is shown, add 45
    height += 45;
    frame.size.height = height;

    self.view.frame = frame;
    self.preferredContentSize = frame.size;

    // This has to be done, otherwise the width is not set for some reason
    frame = self.containerView.frame;
    frame.size.height = height;
    self.containerView.frame = frame;
}

- (void)addBlurViewWithStyle:(UIBlurEffectStyle)style {
    self.contentView.backgroundColor = UIColor.clearColor;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [((UIVisualEffectView *)self.blurView) _setCornerRadius:self.cornerRadius];
    self.blurView.frame = self.view.bounds;
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.contentView insertSubview:self.blurView atIndex:0];
}

- (void)setContainerSize:(CGSize)containerSize {
    _containerSize = containerSize;
    [self updatePreferredContentSize];
}

@end

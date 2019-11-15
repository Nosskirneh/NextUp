#import "NextUpManager.h"
#import "SettingsKeys.h"
#import "Common.h"
#import "Headers.h"
#import "DRMValidateOptions.mm"
#import "notify.h"


NextUpManager *manager;

/* Adding the widget */
%hook MediaControlsPanelViewController

%property (nonatomic, retain) NextUpViewController *nextUpViewController;
%property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;

- (void)setDelegate:(id)delegate {
    %orig;

    // This has to be done in `setDelegate` as it seems like the only way to know if its CC/LS is by comparing the delegate class.
    // Not ideal, but it works. Thus, we have to use `setDelegate` as it's executed after `viewDidLoad`.
    [self initNextUp];
}

%new
- (BOOL)NU_isControlCenter {
    return ([self.delegate class] == %c(MediaControlsEndpointsViewController));
}

- (void)setStyle:(int)style {
    %orig;

    self.nextUpViewController.style = style;
}

%new
- (void)initNextUp {
    if (![self isNextUpInitialized]) {
        BOOL controlCenter = [self NU_isControlCenter];
        self.nextUpViewController = [[%c(NextUpViewController) alloc] initWithControlCenter:controlCenter
                                                                                     defaultStyle:self.style
                                                                                          manager:manager];

        if (controlCenter) {
            MediaControlsContainerView *containerView = self.parentContainerView.mediaControlsContainerView;

            if ([containerView respondsToSelector:@selector(nextUpView)]) {
                [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                         selector:@selector(showNextUp)
                                                             name:kShowNextUp
                                                           object:nil];

                [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                         selector:@selector(hideNextUp)
                                                             name:kHideNextUp
                                                           object:nil];

                containerView.nextUpView = self.nextUpViewController.view;
            }
        }

        self.nextUpInitialized = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNextUpDidInitialize
                                                            object:nil
                                                          userInfo:nil];
    }
}

%end
// ---

// The remaining parts (CC/LS) is for changing the heights/y-coordinates of their respective views.
// Can't be done in the panelViewController as they are fundamentally different views.
%group ControlCenter
    %hook CCUIContentModuleContainerViewController

    - (void)setExpanded:(BOOL)expanded {
        %orig;

        if ([self.moduleIdentifier isEqualToString:@"com.apple.mediaremote.controlcenter.nowplaying"])
            manager.controlCenterExpanded = expanded;
    }

    %end

    %hook MediaControlsContainerView

    %property (nonatomic, retain) UIView *nextUpView;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign) BOOL shouldShowNextUp;

    - (void)layoutSubviews {
        %orig;

        if (manager.controlCenterExpanded && self.shouldShowNextUp) {
            CGRect frame = self.frame;
            frame.size.height = 101.0;
            self.frame = frame;

            self.nextUpView.frame = CGRectMake(frame.origin.x,
                                               frame.origin.y + frame.size.height,
                                               frame.size.width,
                                               105);

            if (!self.showingNextUp)
                [self addNextUpView];
        }
    }

    %new
    - (void)addNextUpView {
        [self.superview addSubview:self.nextUpView];
        self.showingNextUp = YES;
    }

    %new
    - (void)showNextUp {
        self.shouldShowNextUp = YES;
        if (!self.showingNextUp)
            [self layoutSubviews];
    }

    %new
    - (void)hideNextUp {
        self.shouldShowNextUp = NO;
        if (self.showingNextUp)
            [self layoutSubviews];
    }

    %end
%end
// ---


%group Lockscreen
    %hook SBDashBoardNotificationAdjunctListViewController

    - (id)init {
        self = %orig;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showNextUp)
                                                     name:kShowNextUp
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(hideNextUp)
                                                     name:kHideNextUp
                                                   object:nil];
        return self;
    }

    %new
    - (SBDashBoardMediaControlsViewController *)mediaControlsViewController {
        SBDashBoardNowPlayingController *nowPlayingController = [self valueForKey:@"_nowPlayingController"];
        return nowPlayingController.controlsViewController;
    }

    %new
    - (void)showNextUp {
        // Mark NextUp as should be visible
        SBDashBoardMediaControlsViewController *mediaControlsViewController = [self mediaControlsViewController];
        mediaControlsViewController.shouldShowNextUp = YES;

        if (mediaControlsViewController.showingNextUp)
            return;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:NO];
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 2;
        [self _updateMediaControlsVisibilityAnimated:YES];
    }

    %new
    - (void)hideNextUp {
        // Mark NextUp as should not be visible
        SBDashBoardMediaControlsViewController *mediaControlsViewController = [self mediaControlsViewController];
        mediaControlsViewController.shouldShowNextUp = NO;
        [mediaControlsViewController removeNextUpView];

        if (!mediaControlsViewController.showingNextUp)
            return;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:YES];
    }

    %end


    %hook SBDashBoardMediaControlsViewController
    %property (nonatomic, assign) BOOL shouldShowNextUp;
    %property (nonatomic, assign) BOOL nu_skipWidgetHeightIncrease;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign) float nextUpHeight;

    - (id)init {
        self = %orig;

        /* This is apparently needed for some reason. It doesn't set NO as default,
           it becomes some value that are undefined and changes */
        self.nu_skipWidgetHeightIncrease = NO;

        float nextUpHeight = 105.0;
        if ([manager slimmedLSMode])
            nextUpHeight -= 40;
        self.nextUpHeight = nextUpHeight;

        return self;
    }

    - (CGSize)preferredContentSize {
        CGSize orig = %orig;
        if (self.shouldShowNextUp && !self.nu_skipWidgetHeightIncrease)
            orig.height += self.nextUpHeight;
        return orig;
    }

    - (void)_layoutMediaControls {
        %orig;

        if (self.shouldShowNextUp)
            [self addNextUpView];
    }

    %new
    - (MediaControlsPanelViewController *)panelViewController {
        return MSHookIvar<MediaControlsPanelViewController *>(self, "_mediaControlsPanelViewController");
    }

    %new
    - (void)addNextUpView {
        CGSize size = [self preferredContentSize];
        if (size.width < 0)
            return;

        MediaControlsPanelViewController *panelViewController = [self panelViewController];
        [self.view addSubview:panelViewController.nextUpViewController.view];

        UIView *nextUpView = panelViewController.nextUpViewController.view;
        nextUpView.frame = CGRectMake(panelViewController.view.frame.origin.x,
                                      size.height - self.nextUpHeight,
                                      size.width,
                                      self.nextUpHeight);
        [self.view addSubview:nextUpView];
        self.showingNextUp = YES;
    }

    %new
    - (void)removeNextUpView {
        [[self panelViewController].nextUpViewController.view removeFromSuperview];
        self.showingNextUp = NO;
    }

    %end

    /* Hide iPhone X buttons */
    %hook SBDashBoardQuickActionsView

    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;

    - (id)initWithFrame:(CGRect)frame delegate:(id)delegate {
        self = %orig;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showNextUp)
                                                     name:kShowNextUp
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(hideNextUp)
                                                     name:kHideNextUp
                                                   object:nil];

        return self;
    }

    %new
    - (void)showNextUp {
        self.showingNextUp = YES;
        [self setAlpha:0];
    }

    %new
    - (void)hideNextUp {
        self.showingNextUp = NO;
    }

    - (void)setAlpha:(CGFloat)alpha {
        if ([self isShowingNextUp] &&
            [self.delegate.dashBoardViewController isShowingMediaControls] &&
            [manager.preferences[kHideXButtons] boolValue])
            return %orig(0.0);
        %orig;
    }

    %end
    // ---
%end
// ---


/* Add haptic feedback to the media buttons */
%group HapticFeedback
    %hook MediaControlsTransportButton
    %property (nonatomic, retain) UIImpactFeedbackGenerator *hapticGenerator;

    - (id)initWithFrame:(CGRect)frame {
        self = %orig;
        self.hapticGenerator = [[%c(UIImpactFeedbackGenerator) alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        return self;
    }

    - (void)_handleTouchUp {
        %orig;
        [self.hapticGenerator impactOccurred];
    }

    %end
%end
// ---

/* ColorFlow 4 support */
%group ColorFlow
    %hook SBDashBoardMediaControlsViewController
    - (void)cfw_colorize:(CFWColorInfo *)colorInfo {
        %orig;

        NextUpViewController *nextUpViewController = [self panelViewController].nextUpViewController;

        nextUpViewController.headerLabel.textColor = colorInfo.primaryColor;
        [nextUpViewController.mediaView cfw_colorize:colorInfo];
    }

    - (void)cfw_revert {
        %orig;

        NextUpViewController *nextUpViewController = [self panelViewController].nextUpViewController;

        nextUpViewController.headerLabel.textColor = nextUpViewController.mediaView.textColor;
        [nextUpViewController.mediaView cfw_revert];
    }
    %end

    %hook NextUpMediaHeaderView

    - (void)cfw_colorize:(CFWColorInfo *)colorInfo {
        %orig;

        self.routingButton.clear.strokeColor = colorInfo.backgroundColor.CGColor;
        self.routingButton.backgroundColor = colorInfo.primaryColor;
    }

    - (void)cfw_revert {
        %orig;

        self.routingButton.clear.strokeColor = self.textColor.CGColor;
        self.routingButton.backgroundColor = self.skipBackgroundColor;
    }

    %end
%end
// ---


/* Nereid support */
%group Nereid
    %hook MediaControlsPanelViewController

    - (void)nrdUpdate {
        %orig;

        UIColor *color = ((NRDManager *)[%c(NRDManager) sharedInstance]).mainColor;
        NextUpViewController *nextUpViewController = self.nextUpViewController;
        nextUpViewController.headerLabel.textColor = color;
        [nextUpViewController.mediaView updateTextColor:color];
    }

    %end
%end


/* Custom views */
%group CustomViews
    %subclass NUSkipButton : UIButton

    %property (nonatomic, retain) CAShapeLayer *clear;
    %property (nonatomic, assign) CGFloat size;

    - (void)setFrame:(CGRect)frame {
        frame.origin.x += (frame.size.width - self.size) / 2;
        frame.origin.y += (frame.size.height - self.size) / 2;
        frame.size.width = self.size;
        frame.size.height = self.size;
        %orig;
    }
    %end

    %subclass NextUpMediaHeaderView : MediaControlsHeaderView

    // Override routing button
    %property (nonatomic, retain) NUSkipButton *routingButton;
    %property (nonatomic, retain) UIColor *textColor;
    %property (nonatomic, assign) CGFloat textAlpha;
    %property (nonatomic, retain) UIColor *skipBackgroundColor;

    - (id)initWithFrame:(CGRect)arg1 {
        self = %orig;

        float size = 26.0;

        self.routingButton = [%c(NUSkipButton) buttonWithType:UIButtonTypeCustom];
        self.routingButton.size = size;
        self.routingButton.layer.cornerRadius = size / 2;
        
        float ratio = 1/3.;
        float crossSize = size * ratio;
        float offset = (size - crossSize) / 2;

        float startPoint = offset;
        float endPoint = offset + crossSize;
        
        UIBezierPath *firstLinePath = [UIBezierPath bezierPath];
        [firstLinePath moveToPoint:CGPointMake(startPoint, startPoint)];
        [firstLinePath addLineToPoint:CGPointMake(endPoint, endPoint)];
        
        UIBezierPath *secondLinePath = [UIBezierPath bezierPath];
        [secondLinePath moveToPoint:CGPointMake(endPoint, startPoint)];
        [secondLinePath addLineToPoint:CGPointMake(startPoint, endPoint)];
        
        [firstLinePath appendPath:secondLinePath];
        
        float lineWidthAndRadius = size * 0.0875;
        
        CAShapeLayer *clear = [CAShapeLayer layer];
        clear.frame = CGRectMake(0, 0, size, size);
        clear.lineCap = kCALineCapRound;
        clear.path = firstLinePath.CGPath;
        clear.fillColor = nil;
        clear.lineWidth = lineWidthAndRadius;
        clear.cornerRadius = lineWidthAndRadius;
        clear.opacity = 1.0;
        [clear setMasksToBounds:YES];
        
        [self.routingButton.layer addSublayer:clear];
        self.routingButton.clear = clear;

        [self addSubview:self.routingButton];

        // Artwork view
        if ([manager hideArtwork] &&
            [UIApplication sharedApplication].userInterfaceLayoutDirection != UIUserInterfaceLayoutDirectionRightToLeft) {
            self.artworkView.hidden = YES;
            self.artworkBackgroundView.hidden = YES;
            self.placeholderArtworkView.hidden = YES;
            self.shadow.hidden = YES;
        }

        return self;
    }

    %new
    - (void)updateSkipBackgroundColor:(UIColor *)color {
        self.skipBackgroundColor = color;

        self.routingButton.backgroundColor = color;
    }

    %new
    - (void)updateTextColor:(UIColor *)color {
        self.textColor = color;

        self.routingButton.clear.strokeColor = color.CGColor;
    }

    %new
    - (CGRect)rectForMaxWidth:(CGRect)frame maxWidth:(CGFloat)maxWidth fallbackOriginX:(CGFloat)fallbackOriginX bonusWidth:(CGFloat)bonusWidth bonusOriginX:(CGFloat)bonusOriginX {
        frame.size.width += bonusWidth;
        if (maxWidth < frame.size.width) {
            if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft)
                frame.origin.x += frame.size.width - maxWidth;
            frame.size.width = maxWidth;
        }

        if (frame.origin.x == 0)
            frame.origin.x = fallbackOriginX;

        frame.origin.x -= bonusOriginX;
        return frame;
    }

    // This is a bit messy, but it's because MPUMarqueeView is weird.
    // Changing its frame doesn't work very well with RTL either...
    - (void)layoutSubviews {
        %orig;

        NUSkipButton *routingButton = self.routingButton;
        UIView *artworkView = self.artworkView;

        if (routingButton.center.x == 0 && routingButton.center.y == 0) { // Coordinates will not be set properly on iOS 11.2.x
            float buttonSize = routingButton.size;
            routingButton.frame = CGRectMake(self.frame.size.width - buttonSize * 2,
                                             artworkView.frame.origin.y + artworkView.frame.size.height / 2 - buttonSize / 2,
                                             buttonSize, buttonSize);
        }

        float maxWidth;
        float fallbackOriginX;
        float bonusWidth = 0.0;
        float bonusOriginX = 0.0;
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
            maxWidth = artworkView.frame.origin.x - routingButton.frame.origin.x - routingButton.frame.size.width - 15;
            fallbackOriginX = routingButton.frame.origin.x + routingButton.frame.size.width + 8;
        } else {
            maxWidth = routingButton.frame.origin.x - artworkView.frame.origin.x - artworkView.frame.size.width - 15;
            fallbackOriginX = artworkView.frame.origin.x + artworkView.frame.size.width + 12;

            if (artworkView.hidden && ![self respondsToSelector:@selector(masqArtwork)]) {
                bonusOriginX = artworkView.frame.size.width + 15;
                bonusWidth += artworkView.frame.size.width;
                maxWidth += bonusWidth;
            }

            if (routingButton.hidden)
                bonusWidth += routingButton.frame.size.width;
        }

        if (routingButton.hidden)
            maxWidth += routingButton.frame.size.width;

        // Primary label
        CGRect frame = self.primaryMarqueeView.frame;
        frame = [self rectForMaxWidth:frame maxWidth:maxWidth fallbackOriginX:fallbackOriginX bonusWidth:bonusWidth bonusOriginX:bonusOriginX];
        self.primaryMarqueeView.frame = frame;

        // Secondary label
        frame = self.secondaryMarqueeView.frame;
        frame = [self rectForMaxWidth:frame maxWidth:maxWidth fallbackOriginX:fallbackOriginX bonusWidth:bonusWidth bonusOriginX:bonusOriginX];
        self.secondaryMarqueeView.frame = frame;

        self.buttonBackground.hidden = YES;
    }

    - (void)_updateStyle {
        %orig;

        self.primaryLabel.alpha = self.textAlpha;
        self.secondaryLabel.alpha = self.textAlpha;

        // Do not color the labels if ColorFlow is active
        if (![manager colorFlowEnabled]) {
            self.primaryLabel.textColor = self.textColor;
            self.secondaryLabel.textColor = self.textColor;
        }

        self.routingButton.alpha = 0.95;
        self.routingButton.userInteractionEnabled = YES;
    }

    %end
%end
// ---


%group PackagePirated
%hook SBCoverSheetPresentationManager

- (void)_cleanupDismissalTransition {
    %orig;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        showPiracyAlert(packageShown$bs());
    });
}

%end
%end


%group Welcome
%hook SBCoverSheetPresentationManager

- (void)_cleanupDismissalTransition {
    %orig;
    showSpringBoardDismissAlert(packageShown$bs(), WelcomeMsg$bs());
}

%end
%end


%group CheckTrialEnded
%hook SBCoverSheetPresentationManager

- (void)_cleanupDismissalTransition {
    %orig;

    if (!manager.trialEnded && check_lic(licensePath$bs(), package$bs()) == CheckInvalidTrialLicense) {
        [manager setTrialEnded];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
        showSpringBoardDismissAlert(packageShown$bs(), TrialEndedMsg$bs());
    }
}

%end
%end

static inline void initTrial() {
    %init(CheckTrialEnded);
}

static inline void initLockscreen() {
    %init(Lockscreen);

    if ([%c(SBDashBoardMediaControlsViewController) instancesRespondToSelector:@selector(cfw_colorize:)])
        %init(ColorFlow);

    if ([c instancesRespondToSelector:@selector(nrdUpdate)])
        %init(Nereid);
}

%ctor {
    if (fromUntrustedSource(package$bs()))
        %init(PackagePirated);

    manager = [[NextUpManager alloc] init];

    // License check – if no license found, present message. If no valid license found, do not init
    switch (check_lic(licensePath$bs(), package$bs())) {
        case CheckNoLicense:
            %init(Welcome);
            return;
        case CheckInvalidTrialLicense:
            initTrial();
            return;
        case CheckValidTrialLicense:
            initTrial();
            break;
        case CheckValidLicense:
            break;
        case CheckInvalidLicense:
        case CheckUDIDsDoNotMatch:
        default:
            return;
    }
    // ---
    [manager setup];

    %init();
    %init(CustomViews);
    NSNumber *current = manager.preferences[kControlCenter];
    if (!current || [current boolValue])
        %init(ControlCenter);

    current = manager.preferences[kLockscreen];
    if (!current || [current boolValue])
        initLockscreen();

    current = manager.preferences[kHapticFeedbackOther];
    if (!current || [current boolValue])
        %init(HapticFeedback);
}

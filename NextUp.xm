#import "NextUpManager.h"
#import "SettingsKeys.h"
#import "Common.h"
#import "Headers.h"
#import "DRMValidateOptions.mm"


NextUpManager *manager;

/* Adding the widget */
%hook PanelViewController

%property (nonatomic, retain) NextUpViewController *nextUpViewController;

- (void)setDelegate:(id)delegate {
    %orig;

    /* This has to be done in `setDelegate` as it seems to be the
       only way to know if its CC/LS is by comparing the delegate
       class. Not ideal, but it works. Thus, we have to use
       `setDelegate` as it's executed after `viewDidLoad`. */

    BOOL controlCenter = [self NU_isControlCenter];
    /* If the current mode is not enabled, return here */
    if ((!controlCenter && ![manager lockscreenEnabled]) ||
        (controlCenter && ![manager controlCenterEnabled]))
        return;
    [(UIViewController<PanelViewController> *)self initNextUpInControlCenter:controlCenter];
}

%new
- (BOOL)NU_isControlCenter {
    return ([((UIViewController<PanelViewController> *)self).delegate class] == %c(MediaControlsEndpointsViewController));
}

- (void)setStyle:(int)style {
    %orig;
    ((UIViewController<PanelViewController> *)self).nextUpViewController.style = style;
}

%new
- (void)initNextUpInControlCenter:(BOOL)controlCenter {
    UIViewController<PanelViewController> *controller = (UIViewController<PanelViewController> *)self;
    if (!controller.nextUpViewController) {
        controller.nextUpViewController = [[%c(NextUpViewController) alloc] initWithControlCenter:controlCenter
                                                                                     defaultStyle:controller.style
                                                                                          manager:manager];
        if (controlCenter) {
            MediaControlsContainerView *containerView;
            if ([controller.parentContainerView respondsToSelector:@selector(mediaControlsContainerView)])
                containerView = controller.parentContainerView.mediaControlsContainerView;
            else
                containerView = controller.parentContainerView.containerView;

            containerView.nextUpHeight = 105.0;
            containerView.heightWithNextUpActive = 102.0;

            if ([containerView respondsToSelector:@selector(nextUpView)]) {
                [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                         selector:@selector(showNextUp)
                                                             name:kShowNextUp
                                                           object:nil];

                [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                         selector:@selector(hideNextUp)
                                                             name:kHideNextUp
                                                           object:nil];

                containerView.nextUpView = controller.nextUpViewController.view;
            }
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kNextUpDidInitialize
                                                            object:nil
                                                          userInfo:nil];
    }
}

%end
// ---


/* The remaining parts (CC/LS) is for changing the height/y-coordinate
   of their respective views. Can't be done in the panelViewController
   as they are fundamentally different views. */
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
    %property (nonatomic, assign) float nextUpHeight;
    %property (nonatomic, assign) float heightWithNextUpActive;

    - (void)layoutSubviews {
        %orig;

        if (manager.controlCenterExpanded && self.shouldShowNextUp) {
            [self prepareFramesForNextUp];

            if (!self.showingNextUp)
                [self addNextUpView];
        }
    }

    %new
    - (void)prepareFramesForNextUp {
        CGRect frame = self.frame;
        frame.size.height = self.heightWithNextUpActive;
        self.frame = frame;

        self.nextUpView.frame = CGRectMake(frame.origin.x,
                                           frame.origin.y + frame.size.height,
                                           frame.size.width,
                                           self.nextUpHeight);
    }

    %new
    - (CGRect)revertFrameForNextUp {
        CGRect frame = self.frame;
        frame.size.height = self.nextUpHeight + self.heightWithNextUpActive;
        return frame;
    }

    %new
    - (void)addNextUpView {
        [self.superview addSubview:self.nextUpView];
        self.showingNextUp = YES;
    }

    %new
    - (void)showNextUp {
        self.shouldShowNextUp = YES;
        if (!self.showingNextUp) {
            [self addNextUpView];
            self.nextUpView.alpha = 0.0f;

            [UIView animateWithDuration:0.25 animations:^{
                [self prepareFramesForNextUp];
                [self layoutIfNeeded];

                self.nextUpView.alpha = 1.0f;
            } completion:nil];
        }
    }

    %new
    - (void)hideNextUp {
        self.shouldShowNextUp = NO;
        if (self.showingNextUp && manager.controlCenterExpanded) {
            CGRect frame = [self revertFrameForNextUp];
            self.showingNextUp = NO;
            [UIView animateWithDuration:0.25 animations:^{
                self.frame = frame;
                [self layoutIfNeeded];

                self.nextUpView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self.nextUpView removeFromSuperview];
            }];
        }
    }

    %end
%end
// ---


%group Lockscreen
    %hook NotificationAdjunctListViewController

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
    - (id<MediaControlsViewController>)mediaControlsViewController {
        id<NowPlayingController> nowPlayingController = [self valueForKey:@"_nowPlayingController"];
        return nowPlayingController.controlsViewController;
    }

    %new
    - (void)showNextUp {
        // Mark NextUp as should be visible
        id<MediaControlsViewController> mediaControlsViewController = [self mediaControlsViewController];
        mediaControlsViewController.shouldShowNextUp = YES;

        if (!mediaControlsViewController.showingNextUp)
            [self reloadMediaWidget];
    }

    %new
    - (void)hideNextUp {
        // Mark NextUp as should not be visible
        id<MediaControlsViewController> mediaControlsViewController = [self mediaControlsViewController];
        mediaControlsViewController.shouldShowNextUp = NO;
        [mediaControlsViewController removeNextUpView];

        if (mediaControlsViewController.showingNextUp)
            [self reloadMediaWidget];
        mediaControlsViewController.showingNextUp = NO;
    }

    %new
    - (void)reloadMediaWidget {
        UIViewController<NotificationAdjunctListViewController> *_self = (UIViewController<NotificationAdjunctListViewController> *)self;
        NSMutableDictionary *items = _self.identifiersToItems;
        id<AdjunctListItem> item = items[@"SBDashBoardNowPlayingAssertionIdentifier"];
        if (!item)
            return;

        [item.platterView removeFromSuperview];
        [self _insertItem:item animated:YES];
    }

    %end


    %hook MediaControlsViewController
    %property (nonatomic, assign) BOOL shouldShowNextUp;
    %property (nonatomic, assign) BOOL nu_skipWidgetHeightIncrease;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign) float nextUpHeight;

    - (id)init {
        UIViewController<MediaControlsViewController> *_self = (UIViewController<MediaControlsViewController> *)%orig;

        /* This is apparently needed for some reason. It doesn't set NO as default,
           it becomes some value that are undefined and changes */
        _self.nu_skipWidgetHeightIncrease = NO;

        float nextUpHeight = 105.0;
        if ([manager slimmedLSMode])
            nextUpHeight -= 40;
        _self.nextUpHeight = nextUpHeight;

        return _self;
    }

    - (CGSize)preferredContentSize {
        CGSize orig = %orig;
        UIViewController<MediaControlsViewController> *_self = (UIViewController<MediaControlsViewController> *)self;
        if (_self.shouldShowNextUp && !_self.nu_skipWidgetHeightIncrease)
            orig.height += _self.nextUpHeight;
        return orig;
    }

    - (void)_layoutMediaControls {
        %orig;

        UIViewController<MediaControlsViewController> *_self = (UIViewController<MediaControlsViewController> *)self;
        if (_self.shouldShowNextUp)
            [_self addNextUpView];
    }

    %new
    - (UIViewController<PanelViewController> *)panelViewController {
        if (%c(MRPlatterViewController))
            return MSHookIvar<MRPlatterViewController *>(self, "_platterViewController");
        return MSHookIvar<MediaControlsPanelViewController *>(self, "_mediaControlsPanelViewController");
    }

    %new
    - (void)addNextUpView {
        CGSize size = [self preferredContentSize];
        if (size.width < 0)
            return;

        UIViewController<PanelViewController> *panelViewController = [self panelViewController];
        UIViewController<MediaControlsViewController> *_self = (UIViewController<MediaControlsViewController> *)self;
        [_self.view addSubview:panelViewController.nextUpViewController.view];

        UIView *nextUpView = panelViewController.nextUpViewController.view;
        nextUpView.frame = CGRectMake(panelViewController.view.frame.origin.x,
                                      size.height - _self.nextUpHeight,
                                      size.width,
                                      _self.nextUpHeight);
        [_self.view addSubview:nextUpView];
        _self.showingNextUp = YES;
    }

    %new
    - (void)removeNextUpView {
        [[self panelViewController].nextUpViewController.view removeFromSuperview];
    }

    %end

    /* Hide iPhone X buttons */
    %hook QuickActionsView

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
        ((UIView<QuickActionsView> *)self).showingNextUp = YES;
        [self setAlpha:0];
    }

    %new
    - (void)hideNextUp {
        ((UIView<QuickActionsView> *)self).showingNextUp = NO;
    }

    - (void)setAlpha:(CGFloat)alpha {
        if ([self isShowingNextUp] &&
            [[manager class] isShowingMediaControls] &&
            [manager.preferences[kHideXButtons] boolValue])
            return %orig(0.0);
        %orig;
    }

    %end
    // ---


    /* Hide home bar */
    %hook HomeAffordanceView

    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;

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
    - (void)showNextUp {
        ((UIView<HomeAffordanceView> *)self).showingNextUp = YES;
        [self setAlpha:0];
    }

    %new
    - (void)hideNextUp {
        ((UIView<HomeAffordanceView> *)self).showingNextUp = NO;
    }

    - (void)setAlpha:(CGFloat)alpha {
        if ([[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible] &&
            [self isShowingNextUp] &&
            [[manager class] isShowingMediaControls] &&
            [manager.preferences[kHideHomeBar] boolValue])
            return %orig(0.0);

        %orig;
    }

    %end
    // ---


    /* Hide home bar */
    %hook SBDashBoardHomeAffordanceView

    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;

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
    - (void)showNextUp {
        self.showingNextUp = YES;
        [self setAlpha:0];
    }

    %new
    - (void)hideNextUp {
        self.showingNextUp = NO;
    }

    - (void)setAlpha:(CGFloat)alpha {
        if ([[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible] &&
            [self isShowingNextUp] &&
            [[manager class] isShowingMediaControls] &&
            [manager.preferences[kHideHomeBar] boolValue])
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
    %hook MediaControlsViewController
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
        [self updateTextColor];
    }

    %end


    /* ColorFlow 5 calls these methods, as it believes the button is a routing button. */
    %hook NUSkipButton

    %new
    - (void)cfw_colorize:(CFWColorInfo *)colorInfo {}

    %new
    - (void)cfw_revert {}

    %end
%end
// ---


/* Nereid support */
%group Nereid
    %hook PanelViewController

    - (void)nrdUpdate {
        %orig;

        UIColor *color = ((NRDManager *)[%c(NRDManager) sharedInstance]).mainColor;
        NextUpViewController *nextUpViewController = ((UIViewController<PanelViewController> *)self).nextUpViewController;
        nextUpViewController.headerLabel.textColor = color;
        [nextUpViewController.mediaView setNewTextColor:color];
    }

    %end
%end


/* Custom views */
%group CustomViews
    %subclass NUSkipButton : UIButton

    %property (nonatomic, retain) CAShapeLayer *clear;
    %property (nonatomic, assign) CGFloat size;
    // This property is needed in iOS 12 as the default routing button has it
    %property (nonatomic, assign) NSInteger currentMode;

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
            self.artworkBackground.hidden = YES;
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
    - (void)setNewTextColor:(UIColor *)color {
        self.textColor = color;
        [self updateTextColor];
    }

    %new
    - (void)updateTextColor {
    	UIColor *color = self.textColor;
        self.primaryLabel.textColor = color;
        self.secondaryLabel.textColor = color;
        self.routingButton.clear.strokeColor = color.CGColor;
    }

    %new
    - (CGRect)rectForMaxWidth:(CGRect)frame
                     maxWidth:(CGFloat)maxWidth
              fallbackOriginX:(CGFloat)fallbackOriginX
                   bonusWidth:(CGFloat)bonusWidth
                 bonusOriginX:(CGFloat)bonusOriginX {
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
        frame = [self rectForMaxWidth:frame
                             maxWidth:maxWidth
                      fallbackOriginX:fallbackOriginX
                           bonusWidth:bonusWidth
                         bonusOriginX:bonusOriginX];
        self.primaryMarqueeView.frame = frame;

        // Secondary label
        frame = self.secondaryMarqueeView.frame;
        frame = [self rectForMaxWidth:frame
                             maxWidth:maxWidth
                      fallbackOriginX:fallbackOriginX
                           bonusWidth:bonusWidth
                         bonusOriginX:bonusOriginX];
        self.secondaryMarqueeView.frame = frame;
    }

    - (void)_updateStyle {
        %orig;

        self.primaryLabel.alpha = self.textAlpha;
        self.secondaryLabel.alpha = self.textAlpha;

        // Do not color the labels if ColorFlow is active
        if (!manager.colorFlowEnabled)
        	[self updateTextColor];

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

static inline void initLockscreen(Class platterClass) {
    Class mediaControlsViewControllerClass = %c(CSMediaControlsViewController);
    if (!mediaControlsViewControllerClass)
        mediaControlsViewControllerClass = %c(SBDashBoardMediaControlsViewController);

    Class adjunctListViewControllerClass = %c(CSNotificationAdjunctListViewController);
    if (!adjunctListViewControllerClass)
        adjunctListViewControllerClass = %c(SBDashBoardNotificationAdjunctListViewController);

    Class quickActionsViewClass = %c(CSQuickActionsView);
    if (!quickActionsViewClass)
        quickActionsViewClass = %c(SBDashBoardQuickActionsView);

    Class homeAffordanceViewClass = %c(CSHomeAffordanceView);
    if (!homeAffordanceViewClass)
        homeAffordanceViewClass = %c(SBDashBoardHomeAffordanceView);
    %init(Lockscreen, MediaControlsViewController = mediaControlsViewControllerClass,
                      NotificationAdjunctListViewController = adjunctListViewControllerClass,
                      QuickActionsView = quickActionsViewClass,
                      HomeAffordanceView = homeAffordanceViewClass);

    if ([mediaControlsViewControllerClass instancesRespondToSelector:@selector(cfw_colorize:)])
        %init(ColorFlow, MediaControlsViewController = mediaControlsViewControllerClass);

    if ([platterClass instancesRespondToSelector:@selector(nrdUpdate)])
        %init(Nereid, PanelViewController = platterClass);
}

%ctor {
    if (fromUntrustedSource(package$bs()))
        %init(PackagePirated);

    manager = [[NextUpManager alloc] init];

    /* License check – if no license found, present message.
       If no valid license was found, do not init. */
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

    /* Load other tweaks if any. */
    dlopen("/Library/MobileSubstrate/DynamicLibraries/ColorFlow4.dylib", RTLD_NOW);

    [manager setup];

    Class platterClass = %c(MRPlatterViewController);
    if (!platterClass)
        platterClass = %c(MediaControlsPanelViewController);
    %init(PanelViewController = platterClass);

    %init(CustomViews);
    if ([manager controlCenterEnabled])
        %init(ControlCenter);

    if ([manager lockscreenEnabled])
        initLockscreen(platterClass);

    NSNumber *haptic = manager.preferences[kHapticFeedbackOther];
    if (!haptic || [haptic boolValue])
        %init(HapticFeedback);
}

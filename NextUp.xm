#import "NextUpManager.h"
#import "Common.h"
#import "Headers.h"
#import "DRMOptions.mm"


NextUpManager *manager;

/* Adding the widget */
%group SpringBoard
    /* Listen on changes of now playing app */
    %hook SBMediaController
    %property (nonatomic, retain) NSDictionary *nextUpPrefs;

    - (id)init {
        SBMediaController *orig = %orig;
        orig.nextUpPrefs = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

        return orig;
    }

    %new
    - (BOOL)isValidApplicationID:(NSString *)bundleID {
        return !self.nextUpPrefs[bundleID] || [self.nextUpPrefs[bundleID] boolValue];
    }

    - (void)_setNowPlayingApplication:(SBApplication *)app {
        NSString *bundleID = app.bundleIdentifier;
        if ([manager.enabledApps containsObject:app.bundleIdentifier] && [self isValidApplicationID:app.bundleIdentifier] && !manager.trialEnded) {
            [manager setMediaApplication:bundleID];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
        } else {
            [manager setMediaApplication:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
        }

        %orig;
    }

    %end

    /* Control Center */
    %hook MediaControlsPanelViewController

    %property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;

    - (void)setDelegate:(id)delegate {
        %orig;

        if ([self NU_isControlCenter])
            [self initNextUp];
    }

    - (void)setStyle:(int)style {
        %orig;

        if ([self NU_isControlCenter]) {
            MediaControlsContainerView *containerView = self.parentContainerView.mediaControlsContainerView;
            containerView.nextUpViewController.style = style;
        }
    }

    %new
    - (BOOL)NU_isControlCenter {
        return ([self.delegate class] == %c(MediaControlsEndpointsViewController));
    }

    %new
    - (void)initNextUp {
        if (![self isNextUpInitialized]) {
            MediaControlsContainerView *containerView = self.parentContainerView.mediaControlsContainerView;

            [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                     selector:@selector(showNextUp)
                                                         name:kShowNextUp
                                                       object:nil];

            [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                     selector:@selector(hideNextUp)
                                                         name:kHideNextUp
                                                       object:nil];

            containerView.nextUpViewController = [[%c(NextUpViewController) alloc] init];
            containerView.nextUpViewController.cornerRadius = 15;
            containerView.nextUpViewController.manager = manager;
            containerView.nextUpViewController.controlCenter = YES;

            self.nextUpInitialized = YES;
        }
    }

    %end

    %hook CCUIContentModuleContainerViewController

    - (void)setExpanded:(BOOL)expanded {
        %orig;

        if ([self.moduleIdentifier isEqualToString:@"com.apple.mediaremote.controlcenter.nowplaying"])
            manager.controlCenterExpanded = expanded;
    }

    %end

    %hook MediaControlsContainerView

    %property (nonatomic, retain) NextUpViewController *nextUpViewController;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign) BOOL shouldShowNextUp;

    - (void)layoutSubviews {
        %orig;

        if (manager.controlCenterExpanded && self.shouldShowNextUp) {
            CGRect frame = self.frame;
            frame.size.height = 101.0;
            self.frame = frame;

            self.nextUpViewController.view.frame = CGRectMake(self.frame.origin.x,
                                                              self.frame.origin.y + self.frame.size.height,
                                                              self.frame.size.width,
                                                              105);

            if (!self.showingNextUp)
                [self addNextUpView];
        }
    }

    %new
    - (void)addNextUpView {
        [self.superview addSubview:self.nextUpViewController.view];

        self.showingNextUp = YES;
    }

    %new
    - (void)showNextUp {
        self.shouldShowNextUp = YES;
        [self layoutSubviews];
    }

    %new
    - (void)hideNextUp {
        self.shouldShowNextUp = NO;
        [self layoutSubviews];
    }

    %end
    // ---


    /* Lockscreen */
    %hook SBDashBoardNotificationAdjunctListViewController

    - (id)init {
        id orig = %orig;
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(showNextUp)
                                                     name:kShowNextUp
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(hideNextUp)
                                                     name:kHideNextUp
                                                   object:nil];
        return orig;
    }

    // Fixes bug when quickly showing the widget again where it would be cut off
    - (void)viewDidLayoutSubviews {
        %orig;

        UIView *itemView = MSHookIvar<UIView *>(self, "_nowPlayingControlsItem");
        CGRect frame = itemView.frame;
        frame.size.height += frame.origin.y;
        frame.origin.y = 0;
        itemView.frame = frame;
    }

    %new
    - (SBDashBoardMediaControlsViewController *)mediaControlsController {
        SBDashBoardNowPlayingController *nowPlayingController = [self valueForKey:@"_nowPlayingController"];
        return nowPlayingController.controlsViewController;
    }

    %new
    - (void)showNextUp {
        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        // Mark NextUp as should be visible
        mediaControlsController.shouldShowNextUp = YES;

        if (mediaControlsController.showingNextUp)
            return;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:NO];
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 2;
        [self _updateMediaControlsVisibilityAnimated:YES];

        // Not restoring width and height here since we want
        // to do it when the animation is complete
    }

    %new
    - (void)hideNextUp {
        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        // Mark NextUp as should be visible
        mediaControlsController.shouldShowNextUp = NO;

        if (!mediaControlsController.showingNextUp)
            return;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:YES];
    }

    // Restore width and height (touches don't work otherwise)
    %new
    - (void)nextUpViewWasAdded {
        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        CGRect frame = mediaControlsController.view.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.frame.size.height;
        mediaControlsController.view.frame = frame;
    }

    %end


    %hook SBDashBoardMediaControlsViewController
    %property (nonatomic, retain) NextUpViewController *nextUpViewController;
    %property (nonatomic, assign) BOOL nextUpNeedPostFix;
    %property (nonatomic, assign) BOOL shouldShowNextUp;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;

    - (void)viewDidLoad {
        %orig;

        [self initNextUp];
    }

    - (CGSize)preferredContentSize {
        CGSize orig = %orig;
        if (self.shouldShowNextUp)
            orig.height += 105;
        return orig;
    }

    - (void)_layoutMediaControls {
        %orig;

        if (self.shouldShowNextUp)
            [self addNextUpView];
    }

    %new
    - (void)initNextUp {
        if(![self isNextUpInitialized]) {
            self.nextUpViewController = [[%c(NextUpViewController) alloc] init];

            BOOL noctisEnabled = NO;
            if (%c(NoctisSystemController)) {
                NSDictionary *noctisPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laughingquoll.noctisxiprefs.settings.plist"];
                noctisEnabled = !noctisPrefs || [noctisPrefs[@"enableMedia"] boolValue];
                self.nextUpViewController.noctisEnabled = noctisEnabled;
            }

            MediaControlsPanelViewController *panelViewController = MSHookIvar<MediaControlsPanelViewController *>(self, "_mediaControlsPanelViewController");
            self.nextUpViewController.style = noctisEnabled ? 2 : panelViewController.style;
            self.nextUpViewController.cornerRadius = 15;
            self.nextUpViewController.manager = manager;

            self.nextUpInitialized = YES;
        }
    }

    - (void)handleEvent:(SBDashBoardEvent *)event {
        %orig;

        if (event.type == 18 && self.nextUpNeedPostFix) { // SignificantUserInteraction
            self.nextUpNeedPostFix = NO;
            [self.nextUpViewController viewDidAppear:YES];
            [[self _presenter] nextUpViewWasAdded];
        }
    }

    %new
    - (void)addNextUpView {
        [self.view addSubview:self.nextUpViewController.view];

        UIView *mediaView = ((UIViewController *)[self valueForKey:@"_mediaControlsPanelViewController"]).view;

        self.nextUpViewController.view.frame = CGRectMake(mediaView.frame.origin.x,
                                                          mediaView.frame.origin.y + mediaView.frame.size.height,
                                                          mediaView.frame.size.width,
                                                          105);
        self.showingNextUp = YES;
        self.nextUpNeedPostFix = YES;
    }

    %new
    - (void)removeNextUpView {
        [self.nextUpViewController.view removeFromSuperview];
        self.showingNextUp = NO;
    }

    %end
    // ---
%end
// ---


/* ColorFlow 4 support */
%group ColorFlow
    %hook SBDashBoardMediaControlsViewController
    - (void)cfw_colorize:(CFWColorInfo *)colorInfo {
        %orig;

        self.nextUpViewController.mediaView.routingButton.tintColor = colorInfo.primaryColor;
        self.nextUpViewController.headerLabel.textColor = colorInfo.primaryColor;
        [self.nextUpViewController.mediaView cfw_colorize:colorInfo];
    }

    - (void)cfw_revert {
        %orig;

        self.nextUpViewController.mediaView.routingButton.tintColor = UIColor.whiteColor;
        self.nextUpViewController.headerLabel.textColor = UIColor.whiteColor;
        [self.nextUpViewController.mediaView cfw_revert];
    }
    %end
%end
// ---


/* Custom views */
%group CustomViews
    #define DIGITAL_TOUCH_BUNDLE [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/DigitalTouchShared.framework"]

    %subclass NULabel : UILabel

    - (void)setAlpha:(CGFloat)alpha {
        %orig(0.63);
    }

    %end

    %subclass NUSkipButton : UIButton

    - (void)setUserInteractionEnabled:(BOOL)enabled {
        %orig(YES);
    }

    - (void)setAlpha:(CGFloat)alpha {
        %orig(0.95);
    }

    %end


    %subclass NextUpMediaHeaderView : MediaControlsHeaderView

    // Override routing button
    %property (nonatomic, retain) NUSkipButton *routingButton;
    %property (nonatomic, retain) NULabel *primaryLabel;
    %property (nonatomic, retain) NULabel *secondaryLabel;

    - (id)initWithFrame:(CGRect)arg1 {
        NextUpMediaHeaderView *orig = %orig;

        orig.routingButton = [%c(NUSkipButton) buttonWithType:UIButtonTypeSystem];
        UIImage *image = [UIImage imageNamed:@"Cancel.png" inBundle:DIGITAL_TOUCH_BUNDLE];
        [orig.routingButton setImage:image forState:UIControlStateNormal];
        [orig addSubview:orig.routingButton];

        orig.primaryLabel = [[%c(NULabel) alloc] initWithFrame:CGRectZero];
        orig.secondaryLabel = [[%c(NULabel) alloc] initWithFrame:CGRectZero];
        [orig.primaryMarqueeView.contentView addSubview:orig.primaryLabel];
        [orig.secondaryMarqueeView.contentView addSubview:orig.secondaryLabel];

        return orig;
    }

    - (void)layoutSubviews {
        %orig;

        float x = self.artworkView.frame.origin.x + self.artworkView.frame.size.width + 12;
        if (CGRectIsEmpty(self.routingButton.frame)) { // Frame will not be set on iOS 11.2.x
            self.routingButton.frame = CGRectMake(self.frame.size.width - 24 * 2,
                                                  self.artworkView.frame.origin.y + self.artworkView.frame.size.height / 2 - 24 / 2,
                                                  24, 24);
        }

        CGRect frame = self.primaryMarqueeView.frame;
        float maxWidth = fabs(self.routingButton.frame.origin.x - self.artworkView.frame.origin.x - self.artworkView.frame.size.width - 15);
        if (self.routingButton.hidden)
            maxWidth += self.routingButton.frame.size.width;

        float primaryMaxWidth = fmin(frame.size.width, maxWidth);
        frame.size.width = primaryMaxWidth;
        frame.origin.x = x;
        self.primaryMarqueeView.frame = frame;

        frame = self.secondaryMarqueeView.frame;
        float secondaryMaxWidth = fmin(frame.size.width, maxWidth);
        frame.origin.x = x;
        frame.size.width = secondaryMaxWidth;
        self.secondaryMarqueeView.frame = frame;

        self.buttonBackground.hidden = YES;
    }

    %end
%end
// ---


%group Welcome
%hook SBLockScreenManager

- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
    BOOL orig = %orig;
    UIViewController *root = [[UIApplication sharedApplication] keyWindow].rootViewController;

    if ([root isKindOfClass:%c(SBHomeScreenViewController)])
        OBFS_UIALERT(root, packageShown$bs(), WelcomeMsg$bs(), OK$bs());

    return orig;
}

%end
%end


// These two groups down below has to be separate as theos otherwise complains
// about double inited groups (even though it's two different switch cases...)
%group CheckTrialEnded
%hook SBLockScreenManager

- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
    BOOL orig = %orig;
    UIViewController *root = [[UIApplication sharedApplication] keyWindow].rootViewController;

    if ([root isKindOfClass:%c(SBHomeScreenViewController)] && check_lic(licensePath$bs(), package$bs()) == CheckInvalidTrialLicense) {
        if (!manager.trialEnded) {
            manager.trialEnded = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
            OBFS_UIALERT(root, packageShown$bs(), TrialEndedMsg$bs(), OK$bs());
        }
    }

    return orig;
}

%end
%end

%group TrialEnded
%hook SBLockScreenManager

- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
    BOOL orig = %orig;
    UIViewController *root = [[UIApplication sharedApplication] keyWindow].rootViewController;

    if ([root isKindOfClass:%c(SBHomeScreenViewController)]) {
        if (!manager.trialEnded) {
            manager.trialEnded = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
            OBFS_UIALERT(root, packageShown$bs(), TrialEndedMsg$bs(), OK$bs());
        }
    }

    return orig;
}

%end
%end


%ctor {
    manager = [[NextUpManager alloc] init];

    // License check – if no license found, present message. If no valid license found, do not init
    switch (check_lic(licensePath$bs(), package$bs())) {
        case CheckNoLicense:
            %init(Welcome);
            return;
        case CheckInvalidTrialLicense:
            %init(TrialEnded);
            return;
        case CheckValidTrialLicense:
            %init(CheckTrialEnded);
            break;
        case CheckInvalidLicense:
            return;
        case CheckValidLicense:
            break;
        case CheckUDIDsDoNotMatch:
            return;
        default:
            return;
    }
    // ---
    [manager setup];

    %init(SpringBoard);
    %init(ColorFlow);
    %init(CustomViews);
}

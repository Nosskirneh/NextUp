#import "NextUpManager.h"

/* Common */
@interface SBIdleTimerGlobalCoordinator
+ (id)sharedInstance;
- (void)resetIdleTimer;
@end


#if __IPHONE_OS_VERSION_MAX_ALLOWED < 100000
typedef enum UIImpactFeedbackStyle : NSInteger {
    UIImpactFeedbackStyleHeavy,
    UIImpactFeedbackStyleLight,
    UIImpactFeedbackStyleMedium
} UIImpactFeedbackStyle;

@interface UIImpactFeedbackGenerator : NSObject
- (id)initWithStyle:(UIImpactFeedbackStyle)style;
- (void)impactOccurred;
@end
#endif


@interface MediaControlsTransportButton : UIButton
@property (nonatomic, retain) UIImpactFeedbackGenerator *hapticGenerator;
@end


@interface MPUMarqueeView : UIView
@property (assign, getter=isMarqueeEnabled, nonatomic) BOOL marqueeEnabled;
@property (nonatomic, readonly) UIView *contentView;
@end


@interface MediaControlsHeaderView : UIView
@property (nonatomic, retain) UIButton *routingButton;
@property (nonatomic, retain) UIImageView *artworkView;
@property (nonatomic, retain) UIImageView *placeholderArtworkView;
@property (nonatomic, retain) UIView *buttonBackground; // iOS 11
@property (nonatomic, retain) UIView *artworkBackground; // iOS 12
@property (nonatomic, retain) UIView *artworkBackgroundView; // iOS 11
@property (nonatomic, retain) UIView *shadow;
@property (nonatomic, retain) MPUMarqueeView *primaryMarqueeView;
@property (nonatomic, retain) MPUMarqueeView *secondaryMarqueeView;
@property (nonatomic, retain) UILabel *primaryLabel;
@property (nonatomic, retain) UILabel *secondaryLabel;
@property (nonatomic, assign) long long style;
@property (nonatomic, retain) NSString *titleString;
@property (nonatomic, retain) NSString *primaryString;
@property (nonatomic, retain) NSString *secondaryString;
- (void)setShouldEnableMarquee:(BOOL)arg1; // 11.1.2
- (void)setMarqueeEnabled:(BOOL)arg1; // 11.3.1

// MASQ
@property (nonatomic, retain) UIView *masqArtwork;
@end


@interface NUSkipButton : UIButton
@property (nonatomic, retain) CAShapeLayer *clear;
@property (nonatomic, assign) CGFloat size;
+ (id)buttonWithSize:(CGFloat)size;
@end

@interface NextUpMediaHeaderView : MediaControlsHeaderView
@property (nonatomic, retain) NUSkipButton *routingButton;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) CGFloat textAlpha;
@property (nonatomic, retain) UIColor *skipBackgroundColor;
- (CGRect)rectForMaxWidth:(CGRect)frame
                 maxWidth:(CGFloat)maxWidth
          fallbackOriginX:(CGFloat)fallbackOriginX
               bonusWidth:(CGFloat)bonusWidth
             bonusOriginX:(CGFloat)bonusOriginX;
- (void)updateSkipBackgroundColor:(UIColor *)color;
- (void)setNewTextColor:(UIColor *)color;
- (void)updateTextColor;
@end


#define kNextUpDidInitialize @"nextUpDidInitialize"

@interface NextUpViewController : UIViewController
@property (nonatomic, retain) UILabel *headerLabel;
@property (assign, nonatomic) long long style;
@property (nonatomic, assign) BOOL showsHeader;
@property (nonatomic, assign) BOOL controlCenter;
@property (nonatomic, retain) NextUpMediaHeaderView *mediaView;
- (id)initWithControlCenter:(BOOL)controlCenter
               defaultStyle:(long long)style;
@end
// ---


/* Control Center */
@interface CCUIContentModuleContainerViewController
@property (nonatomic, assign, readwrite) NSString *moduleIdentifier;
@end


@interface MediaControlsContainerView : UIView
@property (assign, nonatomic) long long style;
@property (nonatomic, retain) UIView *nextUpView;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@property (nonatomic, assign) BOOL shouldShowNextUp;
@property (nonatomic, assign) float nextUpHeight;
@property (nonatomic, assign) float heightWithNextUpActive;
- (void)prepareFramesForNextUp;
- (CGRect)revertFrameForNextUp;
- (void)addNextUpView;
- (void)showNextUp;
@end


@interface MediaControlsParentContainerView : UIView
@property (nonatomic, retain) MediaControlsContainerView *mediaControlsContainerView;
@end


@interface MediaControlsPanelViewController : UIViewController
@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NextUpViewController *nextUpViewController;
@property (nonatomic, retain) MediaControlsParentContainerView *parentContainerView;
@property (assign, nonatomic) long long style;

- (void)initNextUpInControlCenter:(BOOL)controlCenter;
- (BOOL)NU_isControlCenter;
@end
// ---


/* Lockscreen */
@interface SBDashBoardViewController : UIViewController
@property (nonatomic, assign, getter=isShowingMediaControls) BOOL showingMediaControls;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
@property (nonatomic, readonly) SBDashBoardViewController *dashBoardViewController;
@property (readonly) BOOL isLockScreenVisible;
@end

@interface SBDashBoardQuickActionsView : UIView
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
- (void)animateHide:(BOOL)hide;
- (BOOL)shouldHideWithNextUp;
- (BOOL)shouldOverrideAlpha;
@end

@interface SBDashBoardHomeAffordanceView : UIView
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@end

@interface SBDashBoardMediaControlsViewController : UIViewController
@property (nonatomic, assign) BOOL shouldShowNextUp;
@property (nonatomic, assign) BOOL nu_skipWidgetHeightIncrease;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
- (void)addNextUpView;
- (void)removeNextUpView;
- (MediaControlsPanelViewController *)panelViewController;
- (float)nextUpHeight;
@end


@interface SBDashBoardNotificationAdjunctListViewController : UIViewController
@property (nonatomic, assign, getter=isShowingMediaControls) BOOL showingMediaControls;
- (void)_updateMediaControlsVisibilityAnimated:(BOOL)arg;
- (void)nowPlayingController:(id)controller didChangeToState:(NSInteger)state;
- (SBDashBoardMediaControlsViewController *)mediaControlsViewController;
@end


@interface SBDashBoardEvent : NSObject
- (long long)type;
@end


@interface SBDashBoardNowPlayingController : UIViewController
@property (nonatomic, readonly) SBDashBoardMediaControlsViewController *controlsViewController;
@end
// ---



/* ColorFlow */
@interface CFWColorInfo : NSObject
@property(nonatomic, retain) UIColor *backgroundColor;
@property(nonatomic, retain) UIColor *primaryColor;
@property(nonatomic, retain) UIColor *secondaryColor;
@property(nonatomic, assign, getter=isBackgroundDark) BOOL backgroundDark;
@end

@interface MediaControlsHeaderView (ColorFlow)
- (void)cfw_colorize:(CFWColorInfo *)colorInfo;
- (void)cfw_revert;
@end

@interface CFWPrefsManager : NSObject
@property(nonatomic, assign, getter=isLockScreenEnabled) BOOL lockScreenEnabled;
@property(nonatomic, assign, getter=isMusicEnabled) BOOL musicEnabled;
@property(nonatomic, assign, getter=isSpotifyEnabled) BOOL spotifyEnabled;

@property(nonatomic, assign, getter=shouldRemoveArtworkShadow) BOOL removeArtworkShadow;
@property(nonatomic, assign, getter=isLockScreenResizingEnabled) BOOL lockScreenResizingEnabled;

+ (instancetype)sharedInstance;
@end
// ---

/* Nereid */
@interface MediaControlsHeaderView (Nereid)
@property (nonatomic, assign) BOOL nrdEnabled;
- (void)nrdUpdate;
@end

@interface NRDManager : NSObject
@property (nonatomic, retain) UIColor *mainColor;
+ (instancetype)sharedInstance;
@end
// ---

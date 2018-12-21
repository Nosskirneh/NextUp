#import "NUMetadataSaver.h"

/* Common */
@interface CFWColorInfo : NSObject
@property(nonatomic, retain) UIColor *backgroundColor;
@property(nonatomic, retain) UIColor *primaryColor;
@property(nonatomic, retain) UIColor *secondaryColor;
@property(nonatomic, assign, getter=isBackgroundDark) BOOL backgroundDark;
@end


@interface MPUMarqueeView : UIView
@property (assign, getter=isMarqueeEnabled, nonatomic) BOOL marqueeEnabled;
@property (nonatomic, readonly) UIView *contentView;
@end


@interface MediaControlsHeaderView : UIView
@property (nonatomic, retain) UIButton *routingButton;
@property (nonatomic, retain) UIImageView *artworkView;
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

- (void)cfw_colorize:(CFWColorInfo *)colorInfo;
- (void)cfw_revert;
@end


typedef enum UIImpactFeedbackStyle : NSInteger {
    UIImpactFeedbackStyleHeavy,
    UIImpactFeedbackStyleLight,
    UIImpactFeedbackStyleMedium
} UIImpactFeedbackStyle;

@interface UIImpactFeedbackGenerator : NSObject
- (id)initWithStyle:(UIImpactFeedbackStyle)style;
- (void)impactOccurred;
@end


@interface NextUpViewController : UIViewController
@property (nonatomic, retain) UIImpactFeedbackGenerator *hapticGenerator;
@property (nonatomic, retain) UIStackView *view;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NUMetadataSaver *metadataSaver;
@property (nonatomic, retain) UILabel *headerLabel;
@property (nonatomic, retain) MediaControlsHeaderView *mediaView;
@property (nonatomic, assign) BOOL showsHeader;
@property (nonatomic, assign) BOOL noctisEnabled;
@property (nonatomic, assign) BOOL controlCenter;
@property (nonatomic, assign) int background;
@property (nonatomic, assign) CGFloat cornerRadius;
@end
// ---


/* Control Center */
@interface MediaControlsContainerView : UIView
@property (assign, nonatomic) long long style;
@property (nonatomic, retain) NextUpViewController *nextUpViewController;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@property (nonatomic, assign) BOOL shouldShowNextUp;
- (void)addNextUpView;
@end


@interface MediaControlsParentContainerView : UIView
@property (nonatomic, retain) MediaControlsContainerView *mediaControlsContainerView;
@end


@interface MediaControlsPanelViewController : UIViewController
@property (nonatomic, retain) MediaControlsParentContainerView *parentContainerView;
@property (assign, nonatomic) long long style;

@property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;
- (void)initNextUp;
@end
// ---


/* Lockscreen */
@protocol SBDashBoardAdjunctItemHosting
@end

@interface SBDashBoardAdjunctItemView: UIView
@property (nonatomic, weak) UIViewController<SBDashBoardAdjunctItemHosting> *contentHost;
- (void)_layoutContentHost;
@end


@interface SBDashBoardNotificationAdjunctListViewController : UIViewController
- (void)_updateAdjunctListItems;
- (void)_updateMediaControlsVisibility;
- (void)_updateMediaControlsVisibilityAnimated:(BOOL)arg;
- (void)_prepareNowPlayingControlsView;
- (void)nowPlayingController:(id)controller didChangeToState:(NSInteger)state;
- (id)mediaControlsController;
- (void)nextUpViewWasAdded;
@end


@interface SBDashBoardMediaControlsViewController : UIViewController
@property (nonatomic, retain) NextUpViewController *nextUpViewController;
@property (nonatomic, assign) BOOL nextUpNeedPostFix;
@property (nonatomic, assign) BOOL shouldShowNextUp;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;
- (id)_presenter;
- (void)initNextUp;
- (void)addNextUpView;
- (void)removeNextUpView;
@end


@interface SBLockscreenNowPlayingController : NSObject
@property (assign, getter=isEnabled, nonatomic) BOOL enabled;
- (void)_updateToState:(long long)state;
@end


@interface SBDashBoardEvent : NSObject
- (long long)type;
@end

@interface SBDashBoardNowPlayingController : SBLockscreenNowPlayingController
@property (nonatomic, readonly) SBDashBoardMediaControlsViewController *controlsViewController;
@end


@interface UIVisualEffectView (Missing)
- (void)_setCornerRadius:(double)arg1;
@end
// ---

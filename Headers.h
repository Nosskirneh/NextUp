#import "NextUpManager.h"

/* Common */
@interface SBIdleTimerGlobalCoordinator
+ (id)sharedInstance;
- (void)resetIdleTimer;
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
@end

@interface NextUpMediaHeaderView : MediaControlsHeaderView
@property (nonatomic, retain) NUSkipButton *routingButton;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) CGFloat textAlpha;
@property (nonatomic, retain) UIColor *skipBackgroundColor;
- (CGRect)rectForMaxWidth:(CGRect)frame maxWidth:(CGFloat)maxWidth fallbackOriginX:(CGFloat)fallbackOriginX bonusWidth:(CGFloat)bonusWidth bonusOriginX:(CGFloat)bonusOriginX;
- (void)updateTextColor:(UIColor *)color;
- (void)updateSkipBackgroundColor:(UIColor *)color;
@end


#define kNextUpDidInitialize @"nextUpDidInitialize"

@interface NextUpViewController : UIViewController
@property (nonatomic, retain) NSBundle *bundle;
@property (nonatomic, retain) UIImpactFeedbackGenerator *hapticGenerator;
@property (nonatomic, retain) UIStackView *view;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NextUpManager *manager;
@property (nonatomic, retain) UILabel *headerLabel;
@property (nonatomic, retain) NextUpMediaHeaderView *mediaView;
@property (nonatomic, assign) BOOL showsHeader;
@property (nonatomic, assign) BOOL controlCenter;
@property (assign, nonatomic) long long style;
- (id)initWithControlCenter:(BOOL)controlCenter defaultStyle:(long long)style manager:(NextUpManager *)manager;
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
- (void)addNextUpView;
@end


@interface MediaControlsParentContainerView : UIView
@property (nonatomic, retain) MediaControlsContainerView *mediaControlsContainerView; // 12.0 and 12.1
@property (nonatomic, retain) MediaControlsContainerView *containerView; // 12.2
@end



@protocol PanelViewController<NSObject>
@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NextUpViewController *nextUpViewController;
@property (nonatomic, retain) MediaControlsParentContainerView *parentContainerView;
@property (assign, nonatomic) long long style;

@property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;
- (void)initNextUp;
- (BOOL)NU_isControlCenter;
@end


@interface MediaControlsPanelViewController : UIViewController<PanelViewController>
@end

@interface MRPlatterViewController : UIViewController<PanelViewController>
@end
// ---


/* Lockscreen */
@protocol CoverSheetViewController
@property (nonatomic, assign, getter=isShowingMediaControls) BOOL showingMediaControls;
@end

@interface CSCoverSheetViewController : UIViewController<CoverSheetViewController>
@end

@interface SBDashBoardViewController : UIViewController<CoverSheetViewController>
@end

@interface CSQuickActionsViewController : UIViewController
@property (assign, nonatomic) CSCoverSheetViewController *coverSheetViewController;
@end

@interface SBDashBoardQuickActionsViewController : UIViewController
@property (assign, nonatomic) SBDashBoardViewController *dashBoardViewController;
@end


@protocol QuickActionsView
@property (nonatomic, retain) SBDashBoardQuickActionsViewController *delegate;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@end

@interface CSQuickActionsView : UIView<QuickActionsView>
@end

@interface SBDashBoardQuickActionsView : UIView<QuickActionsView>
@end



@protocol MediaControlsViewController
@property (nonatomic, assign) BOOL shouldShowNextUp;
@property (nonatomic, assign) BOOL nu_skipWidgetHeightIncrease;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@property (nonatomic, assign) float nextUpHeight;
- (void)initNextUp;
- (void)addNextUpView;
- (void)removeNextUpView;
- (UIViewController<PanelViewController> *)panelViewController;
@end


@interface CSMediaControlsViewController : UIViewController<MediaControlsViewController>
@end

@interface SBDashBoardMediaControlsViewController : UIViewController<MediaControlsViewController>
@end

@protocol AdjunctListItem
@property (nonatomic, retain) UIView *platterView;
@end

@interface CSAdjunctListItem : NSObject<AdjunctListItem>
@end

@interface SBDashBoardAdjunctListItem : NSObject<AdjunctListItem>
@end


@protocol NotificationAdjunctListViewController
@property (nonatomic, assign, getter=isShowingMediaControls) BOOL showingMediaControls;
@property (nonatomic, retain) NSMutableDictionary<NSString *, id<AdjunctListItem>> *identifiersToItems;
- (void)_insertItem:(id<AdjunctListItem>)item animated:(BOOL)animate;
- (void)_removeItem:(id<AdjunctListItem>)item animated:(BOOL)animate;
- (void)reloadMediaWidget;
- (void)nowPlayingController:(id)controller didChangeToState:(NSInteger)state;
- (id<MediaControlsViewController>)mediaControlsViewController;
@end

@interface CSNotificationAdjunctListViewController : UIViewController<NotificationAdjunctListViewController>
@end

@interface SBDashBoardNotificationAdjunctListViewController : UIViewController<NotificationAdjunctListViewController>
@end


@interface SBDashBoardEvent : NSObject
- (long long)type;
@end


@protocol NowPlayingController
@property (nonatomic, readonly) id<MediaControlsViewController> controlsViewController;
@end

@interface CSNowPlayingController : UIViewController<NowPlayingController>
@end

@interface SBDashBoardNowPlayingController : UIViewController<NowPlayingController>
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
/* */

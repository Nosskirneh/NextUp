#import "NUMetadataSaver.h"

@protocol SBDashBoardAdjunctItemHosting
@property (assign, nonatomic) CGSize containerSize;
@end

@interface SBDashBoardAdjunctItemView: UIView
@property (nonatomic, weak) UIViewController<SBDashBoardAdjunctItemHosting> *contentHost;
@property (assign, nonatomic) CGSize sizeToMimic;
- (instancetype)initWithRecipe:(long long)recipe options:(unsigned long long)options;
@end

@protocol SBDashBoardNotificationAdjunctListViewControllerDelegate
@required
- (CGSize)sizeToMimicForAdjunctListViewController:(id)arg1;
@optional
- (UIEdgeInsets)insetMarginsToMimicForAdjunctListViewController:(id)arg1;
@end


@interface MPUMarqueeView : UIView
@property (assign, getter=isMarqueeEnabled, nonatomic) BOOL marqueeEnabled;
@end

@interface _MPUMarqueeContentView : UIView
@end


@interface MediaControlsHeaderView : UIView
@property (nonatomic, retain) UIImageView *artworkView;
@property (nonatomic, retain) UIImageView *placeholderArtworkView;
@property (nonatomic, assign) CGSize artworkSize;
@property (nonatomic, retain) UIView *artworkBackgroundView;
@property (nonatomic, retain) UIView *shadow;
@property (nonatomic, retain) MPUMarqueeView *titleMarqueeView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) MPUMarqueeView *primaryMarqueeView;
@property (nonatomic, retain) UILabel *primaryLabel;
@property (nonatomic, retain) MPUMarqueeView *secondaryMarqueeView;
@property (nonatomic, retain) UILabel *secondaryLabel;
@property (nonatomic, assign) long long style;
@property (nonatomic, retain) NSString *titleString;
@property (nonatomic, retain) NSString *primaryString;
@property (nonatomic, retain) NSString *secondaryString;
- (void)setShouldEnableMarquee:(BOOL)arg1; // 11.1.2
- (void)setMarqueeEnabled:(BOOL)arg1; // 11.3.1
// - (void)setShouldUsePlaceholderArtwork:(BOOL)arg1;
@end  


@interface NextUpDashBoardAdjunctItemView : SBDashBoardAdjunctItemView
@end

@interface NextUpViewController : UIViewController <SBDashBoardAdjunctItemHosting>
@property (nonatomic, retain) UIStackView *view;
@property (nonatomic, retain) UIView *blurView;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NUMetadataSaver *metadataSaver;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) MediaControlsHeaderView *mediaView;
@property (nonatomic, retain) SBDashBoardAdjunctItemView *containerView;
@property (assign, nonatomic) CGSize containerSize;
@property (nonatomic, assign) BOOL showsHeader;
@property (nonatomic, assign) int background;
@property (nonatomic, assign) CGFloat cornerRadius;
@end


@interface SBDashBoardNotificationAdjunctListViewController: UIViewController {
    UIStackView *_stackView;
}
@property (nonatomic, retain) NextUpViewController *nextUpViewController;
@property (nonatomic, retain) SBDashBoardAdjunctItemView *nextUpContainerView;
// @property (nonatomic, retain) UIImpactFeedbackGenerator *hapticGenerator;
@property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
@property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;
- (void)insertNextUpSubviewAtEnd;
- (BOOL)isShowingMediaControls;
- (void)initNextUpContainerView;
- (void)showNextUp;
- (void)hideNextUp;
- (void)dismissingNextUp:(UIPanGestureRecognizer *)sender;
@end


@interface MTSystemPlatterMaterialSettings : NSObject
+(MTSystemPlatterMaterialSettings *)sharedMaterialSettings;
@end

@interface MTMaterialView : UIView
+ (MTMaterialView *)materialViewWithRecipe:(NSInteger)arg1 options:(NSUInteger)arg2;
+ (MTMaterialView *)materialViewWithSettings:(MTSystemPlatterMaterialSettings *)arg1 options:(NSUInteger)arg2 initialWeighting:(CGFloat)arg3 scaleAdjustment:(id)arg4;
@end





@interface NCNotificationListSectionHeaderView: UICollectionReusableView
+ (UIFont *)_labelFont;
@end


@interface SBUILegibilityLabel: UIView
@property (nonatomic,copy) NSString *string;
@property (nonatomic,copy) UIColor *textColor;
@property (nonatomic,retain) UIFont *font;
@end


@interface UIVisualEffectView (Missing)
- (void)_setCornerRadius:(double)arg1;
@end

#import "Common.h"

@interface NextUpManager : NSObject {
    NSMutableSet *_enabledApps;
    BOOL _cfLockscreen;
}
@property (nonatomic, readonly) NSSet *enabledApps;
@property (nonatomic, assign, readwrite) NSString *mediaApplication;
@property (nonatomic, readonly) NSDictionary *metadata;

@property (nonatomic, readonly) BOOL slimmedLSMode;
@property (nonatomic, readonly) BOOL hideOnEmpty;
@property (nonatomic, readonly) BOOL hideArtwork;
@property (nonatomic, readonly) BOOL hideXButtons;
@property (nonatomic, readonly) BOOL hideHomeBar;

@property (nonatomic, readonly) BOOL hapticFeedbackSkip;
@property (nonatomic, readonly) BOOL hapticFeedbackOther;

@property (nonatomic, readonly) BOOL controlCenterEnabled;
@property (nonatomic, readonly) BOOL lockscreenEnabled;

@property (nonatomic, assign, readwrite) BOOL controlCenterExpanded;
@property (nonatomic, assign, readonly) BOOL trialEnded;
@property (nonatomic, assign, readonly) BOOL colorFlowEnabled;
@property (nonatomic, assign, readonly) BOOL flowEnabled;
+ (BOOL)isShowingMediaControls;
- (void)setup;
- (void)setTrialEnded;
- (BOOL)hasContent;
@end

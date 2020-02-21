#import "Common.h"

@interface NextUpManager : NSObject {
    NSMutableSet *_enabledApps;
    BOOL _cfLockscreen;
}
@property (nonatomic, readonly) NSSet *enabledApps;
@property (nonatomic, readonly) NSDictionary *preferences;
@property (nonatomic, readonly) NSDictionary *metadata;
@property (nonatomic, assign, readwrite) NSString *mediaApplication;
@property (nonatomic, assign, readwrite) BOOL controlCenterExpanded;
@property (nonatomic, assign, readonly) BOOL trialEnded;
@property (nonatomic, assign, readonly) BOOL colorFlowEnabled;
@property (nonatomic, assign, readonly) BOOL flowEnabled;
+ (BOOL)isShowingMediaControls;
- (void)setup;
- (void)setTrialEnded;
- (BOOL)slimmedLSMode;
- (BOOL)hideOnEmpty;
- (BOOL)hideArtwork;
- (BOOL)controlCenterEnabled;
- (BOOL)lockscreenEnabled;
@end

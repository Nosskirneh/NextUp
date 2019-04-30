#import "Common.h"

@interface NextUpManager : NSObject {
	NSMutableSet *_enabledApps;
}
@property (nonatomic, readonly) NSSet *enabledApps;
@property (nonatomic, readonly) NSDictionary *preferences;
@property (nonatomic, readonly) NSDictionary *metadata;
@property (nonatomic, assign, readwrite) NSString *mediaApplication;
@property (nonatomic, assign, readwrite) BOOL controlCenterExpanded;
@property (nonatomic, assign, readonly) BOOL trialEnded;
- (void)setup;
- (void)reloadPreferences;
- (void)setTrialEnded;
- (BOOL)slimmedLSMode;
- (BOOL)hideOnEmpty;
@end

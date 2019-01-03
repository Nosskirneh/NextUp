#import "Common.h"

@interface NextUpManager : NSObject {
	NSMutableSet *_enabledApps;
}
@property (nonatomic, readonly) NSSet *enabledApps;
@property (nonatomic, readonly) NSDictionary *metadata;
@property (nonatomic, assign, readwrite) NSString *mediaApplication;
@property (nonatomic, assign, readwrite) BOOL controlCenterExpanded;
@property (nonatomic, assign, readwrite) BOOL trialEnded;
- (void)setup;
@end

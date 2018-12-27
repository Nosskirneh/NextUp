#import "Common.h"

@interface NextUpManager : NSObject
@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, assign, readwrite) NSString *mediaApplication;
@property (nonatomic, assign, readwrite) BOOL controlCenterExpanded;
@property (nonatomic, readonly, retain) NSSet *enabledApps;
@end

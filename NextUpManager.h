#import "Common.h"

@interface NextUpManager : NSObject
@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, assign, readwrite) NUMediaApplication mediaApplication;
@property (nonatomic, assign, readwrite) BOOL controlCenterExpanded;
@end

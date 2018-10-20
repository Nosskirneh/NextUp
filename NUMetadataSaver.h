#import "Common.h"

@interface NUMetadataSaver : NSObject
@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, assign, readwrite) NUMediaApplication mediaApplication;
@end

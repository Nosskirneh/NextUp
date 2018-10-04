#import "NUMetadataSaver.h"
#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation NUMetadataSaver

- (id)init {
    self = [super init];

    CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c runServerOnCurrentThread];
    [c registerForMessageName:kNextTracksMessage target:self selector:@selector(handleIncomingMessage:withUserInfo:)];

    return self;
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    self.metadatas = dict[@"upcoming"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp
                                                        object:nil];
}

@end

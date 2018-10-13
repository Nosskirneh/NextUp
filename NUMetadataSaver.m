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
    [c registerForMessageName:kNextTrackMessage target:self selector:@selector(handleIncomingMessage:withUserInfo:)];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearMetadata)
                                                 name:kClearMetadata
                                               object:nil];

    return self;
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    self.metadata = dict;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMetadata
                                                        object:nil];
}

- (void)clearMetadata {
	self.metadata = nil;
}

@end

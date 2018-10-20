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

    return self;
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    // If Spotify is running in background and changed track on a Connect device,
    // but Deezer is playing music at the device: do nothing
    if ([dict[@"mediaApplication"] intValue] != self.mediaApplication)
        return;

    self.metadata = dict[@"metadata"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                        object:nil];
}

- (void)setMediaApplication:(NUMediaApplication)app {
    _mediaApplication = app;

    self.metadata = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                        object:nil];
}

@end

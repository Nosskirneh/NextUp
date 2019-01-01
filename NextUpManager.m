#import "NextUpManager.h"
#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation NextUpManager

- (id)init {
    self = [super init];

    CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c runServerOnCurrentThread];
    [c registerForMessageName:kRegisterApp target:self selector:@selector(handleIncomingMessage:withUserInfo:)];
    [c registerForMessageName:kNextTrackMessage target:self selector:@selector(handleIncomingMessage:withUserInfo:)];

    _enabledApps = [NSMutableSet new];

    return self;
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    if ([name isEqualToString:kRegisterApp]) {
        [_enabledApps addObject:dict[kApp]];
    } else {
        // If Spotify is running in background and changed track on a Connect device,
        // but Deezer is playing music at the device: do nothing
        if (self.mediaApplication && ![dict[kApp] isEqualToString:self.mediaApplication])
            return;

        _metadata = dict[@"metadata"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                            object:nil];
    }
}

- (void)setMediaApplication:(NSString *)app {
    _mediaApplication = app;

    _metadata = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                        object:nil];

    // Refetch for the new app
    NSString *manualUpdate = [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kManualUpdate, app];
    notify(manualUpdate);
}

@end

#import "NextUpManager.h"
#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation NextUpManager

- (void)setup {
    CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c runServerOnCurrentThread];
    [c registerForMessageName:kRegisterApp target:self selector:@selector(handleIncomingMessage:withUserInfo:)];
    [c registerForMessageName:kNextTrackMessage target:self selector:@selector(handleIncomingMessage:withUserInfo:)];

    _enabledApps = [NSMutableSet new];
    [self reloadPreferences];
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    [_enabledApps addObject:dict[kApp]];

    if ([name isEqualToString:kNextTrackMessage]) {
        // For example if Spotify is running in background and changed track on a
        // Connect device, but Deezer is playing music at the device: do nothing
        if (self.mediaApplication && ![dict[kApp] isEqualToString:self.mediaApplication])
            return;

        _metadata = dict[kMetadata];
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

- (void)reloadPreferences {
    _preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
}

- (void)setTrialEnded {
    _trialEnded = YES;
}

- (BOOL)hideOnEmpty {
    return self.preferences[kHideOnEmpty] && [self.preferences[kHideOnEmpty] boolValue];
}

@end

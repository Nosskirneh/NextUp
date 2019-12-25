#import "CommonClients.h"
#import "../Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>


void sendNextTrackMetadata(NSDictionary *metadata) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[kApp] = [[NSBundle mainBundle] bundleIdentifier];

    if (metadata)
        dict[kMetadata] = metadata;
    [c sendMessageName:kNextTrackMessage userInfo:dict];
}

void registerApp(NSString *bundleID) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    [c sendMessageName:kRegisterApp userInfo:@{
        kApp: bundleID
    }];
}

BOOL initClient(CFNotificationCallback skipNextCallback, CFNotificationCallback manualUpdateCallback) {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return NO;

    registerApp(bundleID);
    if (skipNextCallback)
        subscribe(skipNextCallback, skipNextID(bundleID));
    if (manualUpdateCallback)
        subscribe(manualUpdateCallback, manualUpdateID(bundleID));
    return YES;
}

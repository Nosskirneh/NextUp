#import "CommonClients.h"
#import "../Common.h"
#import "../SettingsKeys.h"
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

static BOOL _shouldInitClient(NSString *desiredBundleID,
                              NSString *bundleID) {
    if (![desiredBundleID isEqualToString:bundleID])
        return NO;

    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return NO;

    return YES;
}

BOOL shouldInitClient(NSString *desiredBundleID) {
    return _shouldInitClient(desiredBundleID,
                             [NSBundle mainBundle].bundleIdentifier);
}

BOOL initClient(NSString *desiredBundleID,
                CFNotificationCallback skipNextCallback,
                CFNotificationCallback manualUpdateCallback) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!_shouldInitClient(desiredBundleID, bundleID))
        return NO;

    registerApp(bundleID);
    if (skipNextCallback)
        subscribe(skipNextCallback, skipNextID(bundleID));
    if (manualUpdateCallback)
        subscribe(manualUpdateCallback, manualUpdateID(bundleID));
    return YES;
}

static void _registerNotify(NSString *bundleID,
                            notify_handler_t skipNextHandler,
                            notify_handler_t manualUpdateHandler) {
    int _;
    if (skipNextHandler)
        notify_register_dispatch(CFSkipNextID(bundleID),
                                 &_,
                                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l),
                                 skipNextHandler);
    if (manualUpdateHandler)
        notify_register_dispatch(CFManualUpdateID(bundleID),
                                 &_,
                                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l),
                                 manualUpdateHandler);
}

void registerNotify(notify_handler_t skipNextHandler,
                    notify_handler_t manualUpdateHandler) {
    _registerNotify([NSBundle mainBundle].bundleIdentifier,
                    skipNextHandler,
                    manualUpdateHandler);
}

BOOL initClientNotify(NSString *desiredBundleID,
                      notify_handler_t skipNextHandler,
                      notify_handler_t manualUpdateHandler) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!_shouldInitClient(desiredBundleID, bundleID))
        return NO;

    registerApp(bundleID);
    _registerNotify(bundleID, skipNextHandler, manualUpdateHandler);
    return YES;
}

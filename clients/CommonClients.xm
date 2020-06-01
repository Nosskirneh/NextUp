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

static void _registerApp(NSString *bundleID) {
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

static void _registerCallbacks(NSString *bundleID,
                               CFNotificationCallback skipNextCallback,
                               CFNotificationCallback manualUpdateCallback) {
    if (skipNextCallback)
        subscribe(skipNextCallback, skipNextID(bundleID));
    if (manualUpdateCallback)
        subscribe(manualUpdateCallback, manualUpdateID(bundleID));
}

void registerCallbacks(CFNotificationCallback skipNextCallback,
                       CFNotificationCallback manualUpdateCallback) {
    _registerCallbacks([NSBundle mainBundle].bundleIdentifier,
                       skipNextCallback,
                       manualUpdateCallback);
}

static void _registerNotifyTokens(NSString *bundleID,
                                  notify_handler_t skipNextHandler,
                                  notify_handler_t manualUpdateHandler,
                                  int *skipNextToken,
                                  int *manualUpdateToken) {
    if (skipNextHandler)
        notify_register_dispatch(CFSkipNextID(bundleID),
                                 skipNextToken,
                                 dispatch_get_main_queue(),
                                 skipNextHandler);
    if (manualUpdateHandler)
        notify_register_dispatch(CFManualUpdateID(bundleID),
                                 manualUpdateToken,
                                 dispatch_get_main_queue(),
                                 manualUpdateHandler);
}

static void _registerNotify(NSString *bundleID,
                            notify_handler_t skipNextHandler,
                            notify_handler_t manualUpdateHandler) {
    int _;
    _registerNotifyTokens([NSBundle mainBundle].bundleIdentifier,
                    skipNextHandler,
                    manualUpdateHandler,
                    &_, &_);
}

void registerNotify(notify_handler_t skipNextHandler,
                    notify_handler_t manualUpdateHandler) {
    _registerNotify([NSBundle mainBundle].bundleIdentifier,
                    skipNextHandler,
                    manualUpdateHandler);
}

void registerNotifyTokens(notify_handler_t skipNextHandler,
                          notify_handler_t manualUpdateHandler,
                          int *skipNextToken,
                          int *manualUpdateToken) {
    _registerNotifyTokens([NSBundle mainBundle].bundleIdentifier,
                          skipNextHandler,
                          manualUpdateHandler,
                          skipNextToken,
                          manualUpdateToken);
}


BOOL initClient(NSString *desiredBundleID,
                CFNotificationCallback skipNextCallback,
                CFNotificationCallback manualUpdateCallback) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!_shouldInitClient(desiredBundleID, bundleID))
        return NO;

    _registerApp(bundleID);
    _registerCallbacks(bundleID, skipNextCallback, manualUpdateCallback);
    return YES;
}

BOOL initClientNotify(NSString *desiredBundleID,
                      notify_handler_t skipNextHandler,
                      notify_handler_t manualUpdateHandler) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!_shouldInitClient(desiredBundleID, bundleID))
        return NO;

    _registerApp(bundleID);
    _registerNotify(bundleID, skipNextHandler, manualUpdateHandler);
    return YES;
}

#import "NextUpManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <notify.h>
#import <SpringBoard/SBMediaController.h>
#import "SettingsKeys.h"
#import "Common.h"
#import "Headers.h"

#define kSBMediaNowPlayingAppChangedNotification @"SBMediaNowPlayingAppChangedNotification"


SBDashBoardViewController *getDashBoardViewController() {
    SBLockScreenManager *lockscreenManager = (SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance];
    return lockscreenManager.dashBoardViewController;
}


@implementation NextUpManager {
    NSDictionary *_preferences;
}

+ (BOOL)isShowingMediaControls {
    SBDashBoardViewController *dashBoardViewController = getDashBoardViewController();
    return [dashBoardViewController isShowingMediaControls];
}

- (void)setup {
    CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c runServerOnCurrentThread];
    [c registerForMessageName:kRegisterApp
                       target:self
                     selector:@selector(handleIncomingMessage:withUserInfo:)];
    [c registerForMessageName:kNextTrackMessage
                       target:self
                     selector:@selector(handleIncomingMessage:withUserInfo:)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowPlayingAppChanged:)
                                                 name:kSBMediaNowPlayingAppChangedNotification
                                               object:nil];

    int t;
    notify_register_dispatch(kSettingsChanged,
        &t,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l),
        ^(int _) {
            [self reloadPreferences];
        }
    );

    // ColorFlow
    _colorFlowEnabled = %c(CFWPrefsManager) &&
                        ((CFWPrefsManager *)[%c(CFWPrefsManager) sharedInstance]).lockScreenEnabled;

    _enabledApps = [NSMutableSet new];
    [self reloadPreferences];
}

- (BOOL)shouldActivateForApplicationID:(NSString *)bundleID {
    return [_enabledApps containsObject:bundleID] &&
           (!_preferences[bundleID] || [_preferences[bundleID] boolValue]);
}

- (void)nowPlayingAppChanged:(NSNotification *)notification {
    SBMediaController *mediaController = notification.object;
    NSString *bundleID = mediaController.nowPlayingApplication.bundleIdentifier;
    if ([self shouldActivateForApplicationID:bundleID] && !self.trialEnded) {
        [self setMediaApplication:bundleID];

        // If we should not hide on empty, we show NextUp from the beginning.
        // In the other case, this is done from the NextUpViewController
        if (![self hideOnEmpty])
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
    } else {
        [self setMediaApplication:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
    }
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    [_enabledApps addObject:dict[kApp]];

    if ([name isEqualToString:kNextTrackMessage]) {
        // For example if Spotify is running in background and changed track on a
        // Connect device, but Deezer is playing music at the device: do nothing
        if (!self.mediaApplication ||
            ![dict[kApp] isEqualToString:self.mediaApplication])
            return;

        _metadata = dict[kMetadata];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                            object:_metadata];
    }
}

- (void)setMediaApplication:(NSString *)app {
    _mediaApplication = app;

    _metadata = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                        object:nil];

    // Refetch for the new app
    NSString *manualUpdate = [NSString stringWithFormat:@"%@/%@/%@",
                              NEXTUP_IDENTIFIER, kManualUpdate, app];
    notify_post([manualUpdate UTF8String]);
}

- (void)reloadPreferences {
    _preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
}

- (void)setTrialEnded {
    _trialEnded = YES;
}

- (BOOL)slimmedLSMode {
    NSNumber *value = _preferences[kSlimmedLSMode];
    return value && [value boolValue];
}

- (BOOL)hideOnEmpty {
    NSNumber *value = _preferences[kHideOnEmpty];
    return value && [value boolValue];
}

- (BOOL)hideArtwork {
    NSNumber *value = _preferences[kHideArtwork];
    return value && [value boolValue];
}

- (BOOL)hideXButtons {
    NSNumber *value = _preferences[kHideXButtons];
    return value && [value boolValue];
}

- (BOOL)hideHomeBar {
    NSNumber *value = _preferences[kHideHomeBar];
    return value && [value boolValue];
}

- (BOOL)hapticFeedbackSkip {
    NSNumber *value = _preferences[kHapticFeedbackSkip];
    return !value || [value boolValue];
}

- (BOOL)hapticFeedbackOther {
    NSNumber *value = _preferences[kHapticFeedbackOther];
    return !value || [value boolValue];
}

- (BOOL)controlCenterEnabled {
    NSNumber *value = _preferences[kControlCenter];
    return !value || [value boolValue];
}

- (BOOL)lockscreenEnabled {
    NSNumber *value = _preferences[kLockscreen];
    return !value || [value boolValue];
}

@end

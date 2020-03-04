#import "NextUpManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <notify.h>
#import <SpringBoard/SBMediaController.h>
#import "SettingsKeys.h"
#import "Common.h"
#import <MediaRemote/MediaRemote.h>
#import "Headers.h"

#define kSBMediaNowPlayingAppChangedNotification @"SBMediaNowPlayingAppChangedNotification"


UIViewController<CoverSheetViewController> *getCoverSheetViewController() {
    SBLockScreenManager *lockscreenManager = (SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance];
    if ([lockscreenManager respondsToSelector:@selector(coverSheetViewController)])
        return lockscreenManager.coverSheetViewController;
    return lockscreenManager.dashBoardViewController;
}


@implementation NextUpManager {
    NSString *_gumpInitialBundleID;
}

+ (BOOL)isShowingMediaControls {
    UIViewController<CoverSheetViewController> *coverSheetViewController = getCoverSheetViewController();
    return [coverSheetViewController isShowingMediaControls];
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

    // ColorFlow & Flow support
    _colorFlowEnabled = %c(CFWPrefsManager) &&
                        ((CFWPrefsManager *)[%c(CFWPrefsManager) sharedInstance]).lockScreenEnabled;
    _flowEnabled = %c(MMServer) != nil;

    // Gump support
    [self fetchNowPlayingApp];

    _enabledApps = [NSMutableSet new];
    [self reloadPreferences];
}

- (void)fetchNowPlayingApp {
    MRMediaRemoteGetNowPlayingApplicationPID(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l),
                                             ^(int pid) {
        if (pid != 0) {
            FBApplicationProcess *app = [[%c(FBProcessManager) sharedInstance] applicationProcessForPID:pid];
            /* If the current media app is supported by NextUp,
               it will respond to a manual update request. */
            NSString *bundleID = app.bundleIdentifier;
            _gumpInitialBundleID = bundleID;
            [self sendManualUpdate:bundleID];
        }
    });
}

- (BOOL)shouldActivateForApplicationID:(NSString *)bundleID {
    return [_enabledApps containsObject:bundleID] &&
           (!self.preferences[bundleID] || [self.preferences[bundleID] boolValue]);
}

- (void)nowPlayingAppChanged:(NSNotification *)notification {
    SBMediaController *mediaController = notification.object;
    NSString *bundleID = mediaController.nowPlayingApplication.bundleIdentifier;
    [self shouldConfigureForMediaApplication:bundleID];
}

- (void)shouldConfigureForMediaApplication:(NSString *)bundleID {
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
    NSString *bundleID = dict[kApp];
    [_enabledApps addObject:bundleID];

    if ([_gumpInitialBundleID isEqualToString:bundleID]) {
        _gumpInitialBundleID = nil;
        [self shouldConfigureForMediaApplication:bundleID];
    }

    if ([name isEqualToString:kNextTrackMessage]) {
        // For example if Spotify is running in background and changed track on a
        // Connect device, but Deezer is playing music at the device: do nothing
        if (!self.mediaApplication ||
            ![bundleID isEqualToString:self.mediaApplication])
            return;

        _metadata = dict[kMetadata];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                            object:_metadata];
    }
}

- (void)setMediaApplication:(NSString *)bundleID {
    _mediaApplication = bundleID;

    _metadata = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                        object:nil];
    [self sendManualUpdate:bundleID];
}

- (void)sendManualUpdate:(NSString *)bundleID {
    NSString *manualUpdate = [NSString stringWithFormat:@"%@/%@/%@",
                              NEXTUP_IDENTIFIER, kManualUpdate, bundleID];
    notify_post([manualUpdate UTF8String]);
}

- (void)reloadPreferences {
    _preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
}

- (void)setTrialEnded {
    _trialEnded = YES;
}

- (BOOL)slimmedLSMode {
    return self.preferences[kSlimmedLSMode] && [self.preferences[kSlimmedLSMode] boolValue];
}

- (BOOL)hideOnEmpty {
    return self.preferences[kHideOnEmpty] && [self.preferences[kHideOnEmpty] boolValue];
}

- (BOOL)hideArtwork {
    return self.preferences[kHideArtwork] && [self.preferences[kHideArtwork] boolValue];
}

- (BOOL)controlCenterEnabled {
    NSNumber *value = self.preferences[kControlCenter];
    return !value || [value boolValue];
}

- (BOOL)lockscreenEnabled {
    NSNumber *value = self.preferences[kLockscreen];
    return !value || [value boolValue];
}

@end

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
    NSString *_pendingMediaApplication;
    BOOL _showingNextUp;
}

+ (BOOL)isShowingMediaControls {
    SBDashBoardViewController *dashBoardViewController = getDashBoardViewController();
    return [dashBoardViewController isShowingMediaControls];
}

+ (instancetype)sharedInstance {
    static NextUpManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
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

- (float)lockscreenHeight {
    if (!_showingNextUp)
        return 0.f;

    float height = 105.f;
    if (self.slimmedLSMode)
        height -= 40.f;
    return height;
}

- (void)nowPlayingAppChanged:(NSNotification *)notification {
    SBMediaController *mediaController = notification.object;
    NSString *bundleID = mediaController.nowPlayingApplication.bundleIdentifier;
    [self tryConfigureForMediaApplication:bundleID];
}

- (BOOL)tryConfigureForMediaApplication:(NSString *)bundleID {
    if (!bundleID || (_preferences[bundleID] && [_preferences[bundleID] boolValue]) || _trialEnded)
        goto hide;

    if ([_enabledApps containsObject:bundleID]) {
        [self configureForMediaApplication:bundleID skipUpdateLabels:NO];
        return YES;
    } else {
        _pendingMediaApplication = bundleID;
        [self sendManualUpdate:bundleID];
    }

    hide:
    [self setMediaApplication:nil];
    [self hide];
    return NO;
}

- (void)show {
    _showingNextUp = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
}

- (void)hide {
    _showingNextUp = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
}

- (void)configureForMediaApplication:(NSString *)bundleID
                    skipUpdateLabels:(BOOL)skipUpdateLabels {
    [self setMediaApplication:bundleID skipUpdateLabels:skipUpdateLabels];
    // If we should not hide on empty, we show NextUp from the beginning.
    // In the other case, this is done from the NextUpViewController
    if (![self hideOnEmpty]) {
        [self show];
    }
}

- (void)updateLabels {
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLabels
                                                        object:_metadata];
}

- (void)handleIncomingMessage:(NSString *)name withUserInfo:(NSDictionary *)dict {
    if ([name isEqualToString:kNextTrackMessage]) {
        [self handleIncomingNextTrackMessage:dict];
    } else {
        [self handleIncomingRegisterMessage:dict];
    }
}

- (void)handleIncomingNextTrackMessage:(NSDictionary *)dict {
    [self handleIncomingRegisterMessage:dict];
    NSString *bundleID = dict[kApp];

    if ([bundleID isEqualToString:_pendingMediaApplication]) {
        _pendingMediaApplication = nil;
        [self configureForMediaApplication:bundleID skipUpdateLabels:YES];
    }

    // For example if Spotify is running in background and changed track on a
    // Connect device, but Deezer is playing music at the device: do nothing
    if (!self.mediaApplication || ![bundleID isEqualToString:self.mediaApplication])
        return;

    _metadata = dict[kMetadata];
    [self updateLabels];

    if (!_metadata && self.hideOnEmpty && _showingNextUp) {
        [self hide];
    } else if (_metadata && !_showingNextUp) {
        [self show];
    }
}

- (void)handleIncomingRegisterMessage:(NSDictionary *)dict {
    NSString *bundleID = dict[kApp];
    [_enabledApps addObject:bundleID];
}

- (void)setMediaApplication:(NSString *)bundleID
           skipUpdateLabels:(BOOL)skipUpdateLabels {
    _mediaApplication = bundleID;
    _metadata = nil;

    if (!skipUpdateLabels)
        [self updateLabels];

    if (bundleID)
        [self sendManualUpdate:bundleID];
}

- (void)setMediaApplication:(NSString *)bundleID {
    [self setMediaApplication:bundleID skipUpdateLabels:NO];
}

- (void)sendManualUpdate:(NSString *)bundleID {
    NSString *manualUpdate = [NSString stringWithFormat:@"%@/%@/%@",
                              NEXTUP_IDENTIFIER, kManualUpdate, bundleID];
    notify_post([manualUpdate UTF8String]);
}

- (BOOL)hasContent {
    return _metadata != nil;
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

- (float)extraBottomPadding {
    NSNumber *value = _preferences[kExtraBottomPadding];
    return value ? [value floatValue] : 0.f;
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

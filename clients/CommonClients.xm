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


#define kAnghamiBundleID @"com.anghami.anghami"
#define kAudioMackBundleID @"com.audiomack.iphone"
#define kDeezerBundleID @"com.deezer.Deezer"
#define kGoogleMusicBundleID @"com.google.PlayMusic"
#define kJetAudioBundleID @"com.jetappfactory.jetaudio"
#define kJioSaavnBundleID @"com.Saavn.Saavn"
#define kMusiBundleID @"com.feelthemusi.musi"
#define kMusicBundleID @"com.apple.Music"
#define kNapsterBundleID @"com.rhapsody.iphone.Napster3"
#define kPodcastsBundleID @"com.apple.podcasts"
#define kSoundCloudBundleID @"com.soundcloud.TouchApp"
#define kSpotifyBundleID @"com.spotify.client"
#define kSpotifyInternalBundleID @"com.spotify.client.internal"
#define kTIDALBundleID @"com.aspiro.TIDAL"
#define kVOXBundleID @"com.coppertino.VoxMobile"
#define kYouTubeMusicBundleID @"com.google.ios.youtubemusic"

static inline NSSet *supportedBundleIDsForApp(SupportedApplication app) {
    switch (app) {
        case Anghami:
            return [NSSet setWithArray:@[kAnghamiBundleID]];
        case AudioMack:
            return [NSSet setWithArray:@[kAudioMackBundleID]];
        case Deezer:
            return [NSSet setWithArray:@[kDeezerBundleID]];
        case GoogleMusic:
            return [NSSet setWithArray:@[kGoogleMusicBundleID]];
        case JetAudio:
            return [NSSet setWithArray:@[kJetAudioBundleID]];
        case JioSaavn:
            return [NSSet setWithArray:@[kJioSaavnBundleID]];
        case Musi:
            return [NSSet setWithArray:@[kMusiBundleID]];
        case Music:
            return [NSSet setWithArray:@[kMusicBundleID]];
        case Napster:
            return [NSSet setWithArray:@[kNapsterBundleID]];
        case Podcasts:
            return [NSSet setWithArray:@[kPodcastsBundleID]];
        case SoundCloud:
            return [NSSet setWithArray:@[kSoundCloudBundleID]];
        case Spotify:
            return [NSSet setWithArray:@[kSpotifyBundleID, kSpotifyInternalBundleID]];
        case TIDAL:
            return [NSSet setWithArray:@[kTIDALBundleID]];
        case VOX:
            return [NSSet setWithArray:@[kVOXBundleID]];
        case YouTubeMusic:
            return [NSSet setWithArray:@[kYouTubeMusicBundleID]];
    }
}

BOOL shouldInitClient(SupportedApplication app) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return NO;

    return [supportedBundleIDsForApp(app) containsObject:bundleID];
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


BOOL initClient(SupportedApplication app,
                CFNotificationCallback skipNextCallback,
                CFNotificationCallback manualUpdateCallback) {
    if (!shouldInitClient(app))
        return NO;

    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    _registerApp(bundleID);
    _registerCallbacks(bundleID, skipNextCallback, manualUpdateCallback);
    return YES;
}

BOOL initClientNotify(SupportedApplication app,
                      notify_handler_t skipNextHandler,
                      notify_handler_t manualUpdateHandler) {
    if (!shouldInitClient(app))
        return NO;

    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    _registerApp(bundleID);
    _registerNotify(bundleID, skipNextHandler, manualUpdateHandler);
    return YES;
}

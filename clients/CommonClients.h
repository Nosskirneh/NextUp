#import "../Common.h"
#import "cfnotify.h"
#import <notify.h>

#define skipNextID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kSkipNext, bundleIdentifier]
#define manualUpdateID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kManualUpdate, bundleIdentifier]

#define CFSkipNextID(bundleIdentifier) [skipNextID(bundleIdentifier) UTF8String]
#define CFManualUpdateID(bundleIdentifier) [manualUpdateID(bundleIdentifier) UTF8String]

#define ARTWORK_WIDTH 60
#define ARTWORK_SIZE CGSizeMake(ARTWORK_WIDTH, ARTWORK_WIDTH)

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata);
BOOL shouldInitClient(NSString *desiredBundleID);
BOOL initClient(NSString *desiredBundleID,
                CFNotificationCallback skipNextCallback,
                CFNotificationCallback manualUpdateCallback);

void registerNotify(notify_handler_t skipNextHandler,
                    notify_handler_t manualUpdateHandler);

BOOL initClientNotify(NSString *desiredBundleID,
                      notify_handler_t skipNextHandler,
                      notify_handler_t manualUpdateHandler);

#ifdef __cplusplus
}
#endif



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
#define kTIDALBundleID @"com.aspiro.TIDAL"
#define kVOXBundleID @"com.coppertino.VoxMobile"
#define kYouTubeMusicBundleID @"com.google.ios.youtubemusic"

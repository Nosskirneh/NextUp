#import "notify.h"

#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]

typedef enum {
    NUUnsupportedApplication,
    NUSpotifyApplication,
    NUDeezerApplication,
    NUMusicApplication,
    NUPodcastsApplication
} NUMediaApplication;

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata, NUMediaApplication app);

#ifdef __cplusplus
}
#endif


#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"
#define kPrefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), NEXTUP_IDENTIFIER]

extern NSString *const kSpotifyBundleID;
extern NSString *const kDeezerBundleID;
extern NSString *const kMusicBundleID;
extern NSString *const kPodcastsBundleID;
extern NSString *const kSpringBoardBundleID;

extern NSString *const kNextTrackMessage;
extern NSString *const kShowNextUp;
extern NSString *const kHideNextUp;
extern NSString *const kUpdateLabels;

extern NSString *const kSPTSkipNext;
extern NSString *const kAPMSkipNext;
extern NSString *const kDZRSkipNext;
extern NSString *const kPODSkipNext;

extern NSString *const kSPTManualUpdate;
extern NSString *const kAPMManualUpdate;
extern NSString *const kDZRManualUpdate;
extern NSString *const kPODManualUpdate;


/* Settings */
extern NSString *const kEnableSpotify;
extern NSString *const kEnableMusic;
extern NSString *const kEnableDeezer;
extern NSString *const kEnablePodcasts;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

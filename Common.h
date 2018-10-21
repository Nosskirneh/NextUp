#import "notify.h"

#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]

typedef enum {
    NUUnsupportedApplication,
    NUSpotifyApplication,
    NUDeezerApplication,
    NUMusicApplication
} NUMediaApplication;

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata, NUMediaApplication app);

#ifdef __cplusplus
}
#endif


#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"

extern NSString *const kSpotifyBundleID;
extern NSString *const kDeezerBundleID;
extern NSString *const kMusicBundleID;
extern NSString *const kSpringBoardBundleID;

extern NSString *const kNextTrackMessage;
extern NSString *const kShowNextUp;
extern NSString *const kHideNextUp;
extern NSString *const kUpdateLabels;

extern NSString *const kSPTSkipNext;
extern NSString *const kAPMSkipNext;
extern NSString *const kDZRSkipNext;

extern NSString *const kSPTManualUpdate;
extern NSString *const kAPMManualUpdate;
extern NSString *const kDZRManualUpdate;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

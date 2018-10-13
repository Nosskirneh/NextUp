#import "notify.h"

#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata);

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
extern NSString *const kNewMetadata;

extern NSString *const kSPTSkipNext;
extern NSString *const kDZRSkipNext;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

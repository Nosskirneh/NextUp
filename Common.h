#import "notify.h"

#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]
#define ARTWORK_SIZE CGSizeMake(60, 60)

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata);

#ifdef __cplusplus
}
#endif


#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"
#define kPrefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), NEXTUP_IDENTIFIER]

extern NSString *const kSpotifyBundleID;
extern NSString *const kDeezerBundleID;
extern NSString *const kMusicBundleID;
extern NSString *const kPodcastsBundleID;
extern NSString *const kYoutubeMusicBundleID;
extern NSString *const kSoundCloudBundleID;
extern NSString *const kSpringBoardBundleID;

extern NSString *const kNextTrackMessage;
extern NSString *const kShowNextUp;
extern NSString *const kHideNextUp;
extern NSString *const kUpdateLabels;

extern NSString *const kSkipNext;
extern NSString *const kManualUpdate;

extern NSString *const kSPTSkipNext;
extern NSString *const kAPMSkipNext;
extern NSString *const kDZRSkipNext;
extern NSString *const kPODSkipNext;
extern NSString *const kYTMSkipNext;
extern NSString *const kSDCSkipNext;

extern NSString *const kSPTManualUpdate;
extern NSString *const kAPMManualUpdate;
extern NSString *const kDZRManualUpdate;
extern NSString *const kPODManualUpdate;
extern NSString *const kYTMManualUpdate;
extern NSString *const kSDCManualUpdate;

extern NSString *const kTitle;
extern NSString *const kSubtitle;
extern NSString *const kSkipable;
extern NSString *const kArtwork;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

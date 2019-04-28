#import "notify.h"

#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]
#define ARTWORK_SIZE CGSizeMake(60, 60)

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata);
void registerApp();

#ifdef __cplusplus
}
#endif


#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"
#define kPrefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), NEXTUP_IDENTIFIER]
#define kPrefChanged [NSString stringWithFormat:@"%@/preferencesChanged", NEXTUP_IDENTIFIER]

extern NSString *const kHasSeenTrialEnded;

extern NSString *const kRegisterApp;
extern NSString *const kNextTrackMessage;
extern NSString *const kApp;
extern NSString *const kMetadata;

extern NSString *const kShowNextUp;
extern NSString *const kHideNextUp;
extern NSString *const kUpdateLabels;

extern NSString *const kSkipNext;
extern NSString *const kManualUpdate;

#define skipNextID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kSkipNext, bundleIdentifier]
#define manualUpdateID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kManualUpdate, bundleIdentifier]

extern NSString *const kTitle;
extern NSString *const kSubtitle;
extern NSString *const kSkipable;
extern NSString *const kArtwork;

extern NSString *const kHideXButtons;
extern NSString *const kHideOnEmpty;
extern NSString *const kHapticFeedbackOther;
extern NSString *const kHapticFeedbackSkip;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

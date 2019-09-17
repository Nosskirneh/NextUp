#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]


#define kPrefChanged [NSString stringWithFormat:@"%@/preferencesChanged", NEXTUP_IDENTIFIER]

extern NSString *const kHasSeenTrialEnded;

extern NSString *const kShowNextUp;
extern NSString *const kHideNextUp;
extern NSString *const kUpdateLabels;

extern NSString *const kControlCenter;
extern NSString *const kLockscreen;
extern NSString *const kHideXButtons;
extern NSString *const kSlimmedLSMode;
extern NSString *const kHideOnEmpty;
extern NSString *const kHideArtwork;
extern NSString *const kHapticFeedbackOther;
extern NSString *const kHapticFeedbackSkip;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

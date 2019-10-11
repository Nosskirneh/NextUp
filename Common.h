#import "notify.h"


#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"
#define kPrefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), NEXTUP_IDENTIFIER]

#import <SpringBoard/SBMediaController.h>
#define isAppCurrentMediaApp(x) [((SBMediaController *)[objc_getClass("SBMediaController") sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]

extern NSString *const kShowNextUp;
extern NSString *const kHideNextUp;
extern NSString *const kUpdateLabels;

extern NSString *const kRegisterApp;
extern NSString *const kNextTrackMessage;
extern NSString *const kApp;
extern NSString *const kMetadata;

extern NSString *const kTitle;
extern NSString *const kSubtitle;
extern NSString *const kSkipable;
extern NSString *const kArtwork;

extern NSString *const kSkipNext;
extern NSString *const kManualUpdate;

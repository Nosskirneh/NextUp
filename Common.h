#import "notify.h"


#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"
#define kPrefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), NEXTUP_IDENTIFIER]

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

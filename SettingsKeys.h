#define NEXTUP_IDENTIFIER @"se.nosskirneh.nextup"
#define kPrefPath [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", NEXTUP_IDENTIFIER]

extern const char *kSettingsChanged;

extern NSString *const kControlCenter;
extern NSString *const kLockscreen;
extern NSString *const kHideXButtons;
extern NSString *const kHideHomeBar;
extern NSString *const kSlimmedLSMode;
extern NSString *const kHideOnEmpty;
extern NSString *const kHideArtwork;
extern NSString *const kHapticFeedbackOther;
extern NSString *const kHapticFeedbackSkip;


@interface UIImage (Private)
+ (id)imageNamed:(id)arg1 inBundle:(id)arg2;
@end

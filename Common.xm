#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

NSString *const kHasSeenTrialEnded = @"hasSeenTrialEnded";

NSString *const kRegisterApp = @"se.nosskirneh.nextup/registerApp";
NSString *const kNextTrackMessage = @"se.nosskirneh.nextup/nextTrack";
NSString *const kApp = @"app";
NSString *const kMetadata = @"metadata";

NSString *const kShowNextUp = @"se.nosskirneh.nextup/showNextUp";
NSString *const kHideNextUp = @"se.nosskirneh.nextup/hideNextUp";
NSString *const kUpdateLabels = @"se.nosskirneh.nextup/updateLabels";

NSString *const kSkipNext = @"skipNext";
NSString *const kManualUpdate = @"manualUpdate";

NSString *const kTitle = @"title";
NSString *const kSubtitle = @"subtitle";
NSString *const kSkipable = @"skipable";
NSString *const kArtwork = @"artwork";

NSString *const kHideXButtons = @"hideXButtons";
NSString *const kSlimmedLSMode = @"slimmedLSMode";
NSString *const kHideOnEmpty = @"hideOnEmpty";
NSString *const kHapticFeedbackOther = @"hapticFeedbackOther";
NSString *const kHapticFeedbackSkip = @"hapticFeedbackSkip";


void sendNextTrackMetadata(NSDictionary *metadata) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[kApp] = [[NSBundle mainBundle] bundleIdentifier];

    if (metadata)
        dict[kMetadata] = metadata;
    [c sendMessageName:kNextTrackMessage userInfo:dict];
}

void registerApp() {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    [c sendMessageName:kRegisterApp userInfo:@{
        kApp: [[NSBundle mainBundle] bundleIdentifier]
    }];
}

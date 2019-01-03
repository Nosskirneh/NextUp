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

NSString *const kSPTSkipNext = @"se.nosskirneh.nextup/skipNext/com.spotify.client";
NSString *const kAPMSkipNext = @"se.nosskirneh.nextup/skipNext/com.apple.Music";
NSString *const kDZRSkipNext = @"se.nosskirneh.nextup/skipNext/com.deezer.Deezer";
NSString *const kPODSkipNext = @"se.nosskirneh.nextup/skipNext/com.apple.podcasts";
NSString *const kYTMSkipNext = @"se.nosskirneh.nextup/skipNext/com.google.ios.youtubemusic";
NSString *const kGPMSkipNext = @"se.nosskirneh.nextup/skipNext/com.google.PlayMusic";
NSString *const kTDLSkipNext = @"se.nosskirneh.nextup/skipNext/com.aspiro.TIDAL";
NSString *const kANGSkipNext = @"se.nosskirneh.nextup/skipNext/com.anghami.anghami";

NSString *const kSPTManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.spotify.client";
NSString *const kAPMManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.apple.Music";
NSString *const kDZRManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.deezer.Deezer";
NSString *const kPODManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.apple.podcasts";
NSString *const kYTMManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.google.ios.youtubemusic";
NSString *const kSDCManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.soundcloud.TouchApp";
NSString *const kGPMManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.google.PlayMusic";
NSString *const kTDLManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.aspiro.TIDAL";
NSString *const kANGManualUpdate = @"se.nosskirneh.nextup/manualUpdate/com.anghami.anghami";

NSString *const kTitle = @"title";
NSString *const kSubtitle = @"subtitle";
NSString *const kSkipable = @"skipable";
NSString *const kArtwork = @"artwork";


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

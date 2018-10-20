#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

// Methods that updates changes to .plist
void sendNextTrackMetadata(NSDictionary *metadata) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c sendMessageName:kNextTrackMessage userInfo:metadata];
}

NSString *const kSpotifyBundleID = @"com.spotify.client";
NSString *const kDeezerBundleID = @"com.deezer.Deezer";
NSString *const kMusicBundleID = @"com.apple.Music";
NSString *const kSpringBoardBundleID = @"com.apple.springboard";

NSString *const kNextTrackMessage = @"se.nosskirneh.nextup/nextTrack";
NSString *const kShowNextUp = @"se.nosskirneh.nextup/showNextUp";
NSString *const kHideNextUp = @"se.nosskirneh.nextup/hideNextUp";
NSString *const kUpdateLabels = @"se.nosskirneh.nextup/updateLabels";
NSString *const kClearMetadata = @"se.nosskirneh.nextup/clearMetadata";

NSString *const kSPTSkipNext = @"se.nosskirneh.nextup/SPTSkipNext";
NSString *const kDZRSkipNext = @"se.nosskirneh.nextup/DZRSkipNext";

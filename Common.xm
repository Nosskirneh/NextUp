#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

// Methods that updates changes to .plist
void sendNextTrackMetadata(NSDictionary *metadata, NUMediaApplication app) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    NSDictionary *dict = @{
    	@"metadata": metadata,
    	@"mediaApplication": @(app)
    };
    [c sendMessageName:kNextTrackMessage userInfo:dict];
}

NSString *const kSpotifyBundleID = @"com.spotify.client";
NSString *const kDeezerBundleID = @"com.deezer.Deezer";
NSString *const kMusicBundleID = @"com.apple.Music";
NSString *const kSpringBoardBundleID = @"com.apple.springboard";

NSString *const kNextTrackMessage = @"se.nosskirneh.nextup/nextTrack";
NSString *const kShowNextUp = @"se.nosskirneh.nextup/showNextUp";
NSString *const kHideNextUp = @"se.nosskirneh.nextup/hideNextUp";
NSString *const kUpdateLabels = @"se.nosskirneh.nextup/updateLabels";

NSString *const kSPTSkipNext = @"se.nosskirneh.nextup/SPTSkipNext";
NSString *const kAPMSkipNext = @"se.nosskirneh.nextup/APMSkipNext";
NSString *const kDZRSkipNext = @"se.nosskirneh.nextup/DZRSkipNext";

NSString *const kSPTManualUpdate = @"se.nosskirneh.nextup/SPTManualUpdate";
NSString *const kAPMManualUpdate = @"se.nosskirneh.nextup/APMManualUpdate";
NSString *const kDZRManualUpdate = @"se.nosskirneh.nextup/DZRManualUpdate";


/* Settings */
NSString *const kEnableSpotify = @"EnableSpotify";
NSString *const kEnableMusic = @"EnableMusic";
NSString *const kEnableDeezer = @"EnableDeezer";

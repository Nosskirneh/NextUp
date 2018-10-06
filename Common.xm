#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

// Methods that updates changes to .plist
void sendNextTracks(NSArray *upcoming) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c sendMessageName:kNextTracksMessage userInfo:@{
        @"upcoming" : upcoming
    }];
}

NSString *const kSpotifyBundleIdentifier = @"com.spotify.client";
NSString *const kDeezerBundleIdentifier = @"com.deezer.Deezer";
NSString *const kMusicBundleIdentifier = @"com.apple.Music";

NSString *const kNextTracksMessage = @"se.nosskirneh.nextup/nextTracks";
NSString *const kShowNextUp = @"se.nosskirneh.nextup/showNextUp";
NSString *const kNewMetadata = @"se.nosskirneh.nextup/newMetadata";

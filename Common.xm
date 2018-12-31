#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

// Methods that updates changes to .plist
void sendNextTrackMetadata(NSDictionary *metadata) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    NSMutableDictionary *dict = [NSMutableDictionary new];
	dict[@"mediaApplication"] = [[NSBundle mainBundle] bundleIdentifier];

    if (metadata)
    	dict[@"metadata"] = metadata;
    [c sendMessageName:kNextTrackMessage userInfo:dict];
}

NSString *const kSpotifyBundleID = @"com.spotify.client";
NSString *const kMusicBundleID = @"com.apple.Music";
NSString *const kDeezerBundleID = @"com.deezer.Deezer";
NSString *const kPodcastsBundleID = @"com.apple.podcasts";
NSString *const kYoutubeMusicBundleID = @"com.google.ios.youtubemusic";
NSString *const kSoundCloudBundleID = @"com.soundcloud.TouchApp";
NSString *const kPlayMusicBundleID = @"com.google.PlayMusic";
NSString *const kTIDALBundleID = @"com.aspiro.TIDAL";
NSString *const kAnghamiBundleID = @"com.anghami.anghami";
NSString *const kSpringBoardBundleID = @"com.apple.springboard";

NSString *const kNextTrackMessage = @"se.nosskirneh.nextup/nextTrack";
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

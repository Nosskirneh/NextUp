#import "Common.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

// Methods that updates changes to .plist
void sendNextTrackMetadata(NSDictionary *metadata, NSString *app) {
    CPDistributedMessagingCenter *c = [%c(CPDistributedMessagingCenter) centerNamed:NEXTUP_IDENTIFIER];
    rocketbootstrap_distributedmessagingcenter_apply(c);

    NSMutableDictionary *dict = [NSMutableDictionary new];
	dict[@"mediaApplication"] = app;

    if (metadata)
    	dict[@"metadata"] = metadata;
    [c sendMessageName:kNextTrackMessage userInfo:dict];
}

NSString *const kSpotifyBundleID = @"com.spotify.client";
NSString *const kMusicBundleID = @"com.apple.Music";
NSString *const kDeezerBundleID = @"com.deezer.Deezer";
NSString *const kPodcastsBundleID = @"com.apple.podcasts";
NSString *const kYoutubeMusicBundleID = @"com.google.ios.youtubemusic";
NSString *const kSpringBoardBundleID = @"com.apple.springboard";

NSString *const kNextTrackMessage = @"se.nosskirneh.nextup/nextTrack";
NSString *const kShowNextUp = @"se.nosskirneh.nextup/showNextUp";
NSString *const kHideNextUp = @"se.nosskirneh.nextup/hideNextUp";
NSString *const kUpdateLabels = @"se.nosskirneh.nextup/updateLabels";

NSString *const kSkipNext = @"SkipNext";
NSString *const kManualUpdate = @"ManualUpdate";

NSString *const kSPTSkipNext = @"se.nosskirneh.nextup/SkipNext/com.spotify.client";
NSString *const kAPMSkipNext = @"se.nosskirneh.nextup/SkipNext/com.apple.Music";
NSString *const kDZRSkipNext = @"se.nosskirneh.nextup/SkipNext/com.deezer.Deezer";
NSString *const kPODSkipNext = @"se.nosskirneh.nextup/SkipNext/com.apple.podcasts";
NSString *const kYTMSkipNext = @"se.nosskirneh.nextup/SkipNext/com.google.ios.youtubemusic";

NSString *const kSPTManualUpdate = @"se.nosskirneh.nextup/ManualUpdate/com.spotify.client";
NSString *const kAPMManualUpdate = @"se.nosskirneh.nextup/ManualUpdate/com.apple.Music";
NSString *const kDZRManualUpdate = @"se.nosskirneh.nextup/ManualUpdate/com.deezer.Deezer";
NSString *const kPODManualUpdate = @"se.nosskirneh.nextup/ManualUpdate/com.apple.podcasts";
NSString *const kYTMManualUpdate = @"se.nosskirneh.nextup/ManualUpdate/com.google.ios.youtubemusic";

NSString *const kTitle = @"title";
NSString *const kSubtitle = @"subtitle";
NSString *const kSkipable = @"skipable";
NSString *const kArtwork = @"artwork";

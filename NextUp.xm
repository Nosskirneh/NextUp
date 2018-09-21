#import <SpringBoard/SBMediaController.h>
#import "NUMetadataSaver.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Common.h"
#import "Spotify.h"
#import "Deezer.h"


#define isAppCurrentMediaApp(x) [((SBMediaController *)[%c(SBMediaController) sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]


NUMetadataSaver *metadataSaver;

/* Fetch Apple Music metadata */
%group Music

@interface MPMusicPlayerController (Addition)
- (NSDictionary *)deserilizeTrack:(MPMediaItem *)track;
- (id)nowPlayingItemAtIndex:(NSUInteger)arg1;
@end


%hook SBMediaController

- (void)setNowPlayingInfo:(id)arg {
    %orig;

    if (![self.nowPlayingApplication.mainSceneID isEqualToString:kMusicBundleIdentifier])
        return;

    MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];

    NSMutableArray *upcomingMetadatas = [NSMutableArray new];
    int i = 1;
    MPMediaItem *item = [player nowPlayingItemAtIndex:i];
    while (item) {
        NSDictionary *metadata = [player deserilizeTrack:item];
        [upcomingMetadatas addObject:metadata];

        i++;
        item = [player nowPlayingItemAtIndex:i];
    };

    HBLogDebug(@"metadatas: %@", upcomingMetadatas);
    //sendNextTracks(upcomingMetadatas);
}

%end

%hook MPMusicPlayerController

%new
- (NSDictionary *)deserilizeTrack:(MPMediaItem *)track {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[@"trackTitle"] = track.title;
    metadata[@"artistTitle"] = track.artist;
    UIImage *artwork = [track.artwork imageWithSize:CGSizeMake(46, 46)];
    metadata[@"artwork"] = artwork;
    return metadata;
}

%end
%end
// ---



/* Spotify */
%group Spotify

SpotifyApplication *getSpotifyApplication() {
    return (SpotifyApplication *)[UIApplication sharedApplication];
}

NowPlayingFeatureImplementation *getRemoteDelegate() {
    return getSpotifyApplication().remoteControlDelegate;
}

SPTNowPlayingTrackMetadataQueue *getTrackMetadataQueue() {
    return getRemoteDelegate().trackMetadataQueue;
}

SPTQueueServiceImplementation *getQueueService() {
    return getRemoteDelegate().queueService;
}


%hook SPTNowPlayingTrackMetadataQueue

%property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;
%property (nonatomic, retain) NSMutableArray *upcomingMetadatas;
%property (nonatomic, assign) NSInteger processingTracksCount;

- (void)player:(id)player didMoveToRelativeTrack:(id)arg {
    %orig;

    if (!self.imageLoader)
        self.imageLoader = [getQueueService().glueImageLoaderFactory createImageLoaderForSourceIdentifier:@"se.nosskirneh.nextup"];

    self.upcomingMetadatas = [NSMutableArray new];
    int i = 1;
    SPTPlayerTrack *track = [self metadataAtRelativeIndex:i];
    while (track) {
        [self deserilizeTrack:track];
        i++;
        track = [self metadataAtRelativeIndex:i];
    };
}

%new
- (void)deserilizeTrack:(SPTPlayerTrack *)track {
    self.processingTracksCount++;

    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[@"trackTitle"] = [track trackTitle];
    metadata[@"artistTitle"] = track.artistTitle;

    // Artwork
    CGSize imageSize = CGSizeMake(46, 46);
    __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

    // Do this lastly
    if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
        [self.imageLoader loadImageForURL:track.coverArtURLSmall imageSize:imageSize completion:^(UIImage *img) {
            self.processingTracksCount--;
            if (img)
                image = img;

            metadata[@"artwork"] = image;
            HBLogDebug(@"metadata: %@", metadata);
            [self.upcomingMetadatas addObject:metadata];

            if (self.processingTracksCount == 0) {
                // Send message to springboard
                HBLogDebug(@"last artwork");
                sendNextTracks(self.upcomingMetadatas);
            }
        }];
    }
}

%end
%end
// ---



/* Deezer */
%group Deezer
%hook DZRMyMusicShuffleQueuer

- (void)setDownloadablesByPlayableUniqueIDs:(NSMutableArray *)array {
    %orig;

    NSMutableArray *upcomingMetadatas = [NSMutableArray new];
    int i = 1;
    DZRDownloadableObject *downloadObject = [self downloadableAtTrackIndex:i];
    while (downloadObject) {
        NSDictionary *metadata = [self deserilizeTrack:downloadObject.playableObject];
        [upcomingMetadatas addObject:metadata];

        i++;
        downloadObject = [self downloadableAtTrackIndex:i];
    };

    sendNextTracks(upcomingMetadatas);
}

%new
- (NSDictionary *)deserilizeTrack:(DeezerTrack *)track {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[@"trackTitle"] = track.title;
    metadata[@"artistTitle"] = track.artistName;
    UIImage *artwork = [track.nowPlayingArtwork imageWithSize:CGSizeMake(46, 46)];
    metadata[@"artwork"] = artwork;
    return metadata;
}


%end
%end
// ---

%group SpringBoard
/* Adding the widget */
/*

%hook ...


%end

*/
%end

%ctor {
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoard);
        %init(Music)
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpotifyBundleIdentifier]) {
        %init(Spotify)
    } else {
        %init(Deezer)
    }

    metadataSaver = [[NUMetadataSaver alloc] init];
}

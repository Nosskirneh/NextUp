#import "YouTubeMusic.h"
#import "../CommonClients.h"
#import <MediaPlayer/MPNowPlayingInfoCenter.h>


static YTMAppDelegate *getYTMAppDelegate() {
    return (YTMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

static GIMMe *gimme() {
    return getYTMAppDelegate().gimme;
}

%hook YTMQueueController

%property (nonatomic, assign) int skipNextNotifyToken;
%property (nonatomic, assign) int manualUpdateNotifyToken;

- (void)commonInit {
    %orig;

    int skipNextNotifyToken;
    int manualUpdateNotifyToken;

    registerNotifyTokens(^(int _) {
            [self skipNext];
        },
        ^(int _) {
            [self fetchNextUp];
        },
        &skipNextNotifyToken,
        &manualUpdateNotifyToken);

    self.skipNextNotifyToken = skipNextNotifyToken;
    self.manualUpdateNotifyToken = manualUpdateNotifyToken;
}

/* This is necessary as it spawns two of these classes, one of which is
   deallocated shortly after. When the `manualUpdate` notification call
   comes, `self` is something entirely different which results in a crash. */
- (void)dealloc {
    notify_cancel(self.skipNextNotifyToken);
    notify_cancel(self.manualUpdateNotifyToken);

    %orig;
}

- (unsigned long long)addQueueItems:(NSArray *)items
                   numItemsToReveal:(long long)reveal
                            atIndex:(unsigned long long)index {
    unsigned long long orig = %orig;

    if (index == self.nextVideoIndex)
        [self fetchNextUp];

    return orig;
}

- (void)moveItemAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    %orig;

    if (from.row == self.nextVideoIndex || to.row == self.nextVideoIndex)
        [self fetchNextUp];
}

- (void)removeVideoAtIndex:(unsigned long long)index {
    %orig;

    if (index == self.nextVideoIndex)
        [self fetchNextUp];
}

- (void)automixController:(id)controller
        didRemoveRenderersAtIndexes:(NSIndexSet *)indexes {
    %orig;

    if ([indexes containsIndex:self.nextVideoIndex])
        [self fetchNextUp];
}

- (void)automixController:(id)controller
        didInsertRenderersAtIndexes:(NSIndexSet *)indexes
        response:(id)arg3 {
    %orig;

    if ([indexes containsIndex:self.nextVideoIndex])
        [self fetchNextUp];
}

- (void)setAutoExtendPlaybackQueueEnabled:(BOOL)enable {
    %orig;

    [self fetchNextUp];
}

- (void)updateMDXPlaybackOrder {
    %orig;

    [self fetchNextUp];
}

%group PlayItemAtIndex_Old
- (void)playItemAtIndex:(unsigned long long)index
         autoPlaySource:(int)autoplay
            atStartTime:(double)starttime {
    %orig;

    [self fetchNextUp];
}
%end

%group PlayItemAtIndex_New
- (void)playItemAtIndex:(unsigned long long)index
        autoPlaySource:(int)autoplay
        isPlaybackControllerInternalTransition:(BOOL)transition
        atStartTime:(double)starttime {
    %orig;

    [self fetchNextUp];
}
%end

%new
- (void)fetchNextUp {
    YTIPlaylistPanelVideoRenderer *next;

    // Using an earlier YouTube Music version?
    if ([self respondsToSelector:@selector(nextVideo)])
        next = self.nextVideo;
    else
        next = [self nextVideoWithAutoplay:[self hasAutoplayVideo]];

    if (next && next.hasThumbnail && next.thumbnail.thumbnailsArray.count > 0) {
        NSArray *thumbnails = next.thumbnail.thumbnailsArray;
        YTIThumbnailDetails_Thumbnail *pickedThumbnail;
        // Find the closest to the size
        for (YTIThumbnailDetails_Thumbnail *thumbnail in thumbnails) {
            pickedThumbnail = thumbnail;
            if (thumbnail.height >= ARTWORK_SIZE.height * [UIScreen mainScreen].scale)
                break;
        }

        NSURL *URL = [NSURL URLWithString:pickedThumbnail.URL];

        YTImageServiceImpl *imageService = [gimme() instanceForType:%c(YTImageService)];
        [imageService makeImageRequestWithURL:URL responseBlock:^(UIImage *image) {
            sendNextTrackMetadata([self serializeTrack:next image:image]);
        } errorBlock:nil];
    } else {
        sendNextTrackMetadata(nil);
    }
}

%new
- (NSDictionary *)serializeTrack:(YTIPlaylistPanelVideoRenderer *)item
                           image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    if (item.hasTitle)
        metadata[kTitle] = [item.title accessibilityLabel];

    if (item.hasShortBylineText)
        metadata[kSubtitle] = [item.shortBylineText accessibilityLabel];

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    if (self.nowPlayingIndex + 1 == self.queueCount)
        metadata[kSkipable] = @NO;

    return metadata;
}

%new
- (void)skipNext {
    [self removeVideoAtIndex:self.nextVideoIndex];
}

/* Fixes an issue where the timestamp slider would get reverted
   to a previous checkpoint when skipping the next track. */
- (void)contentVideoMediaTimeDidChangeToTime:(double)time totalMediaTime:(double)totalTime {
    %orig;

    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *nowPlayingInfo = [center.nowPlayingInfo mutableCopy];
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(time);

    center.nowPlayingInfo = nowPlayingInfo;
}

%end


%ctor {
    if (shouldInitClient(YouTubeMusic)) {
        %init;

        if ([%c(YTMQueueController) instancesRespondToSelector:@selector(playItemAtIndex:
                                                                         autoPlaySource:
                                                                         isPlaybackControllerInternalTransition:
                                                                         atStartTime:)])
            %init(PlayItemAtIndex_New);
        else
            %init(PlayItemAtIndex_Old);
    }
}

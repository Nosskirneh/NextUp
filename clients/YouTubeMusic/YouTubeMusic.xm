#import "YouTubeMusic.h"
#import "../CommonClients.h"


void skipNext(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSkipNext object:nil];
}

void manualUpdate(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kManualUpdate object:nil];
}

YTMAppDelegate *getYTMAppDelegate() {
    return (YTMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

GIMMe *gimme() {
    return getYTMAppDelegate().gimme;
}

%hook YTMQueueController

- (void)commonInit {
    %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(skipNext)
                                                 name:kSkipNext
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchNextUp)
                                                 name:kManualUpdate
                                               object:nil];
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

- (void)automixController:(id)controller didRemoveRenderersAtIndexes:(NSIndexSet *)indexes {
    %orig;

    if ([indexes containsIndex:self.nextVideoIndex])
        [self fetchNextUp];
}

- (void)automixController:(id)controller didInsertRenderersAtIndexes:(NSIndexSet *)indexes response:(id)arg3 {
    %orig;

    if ([indexes containsIndex:self.nextVideoIndex])
        [self fetchNextUp];
}

- (void)setAutoExtendPlaybackQueueEnabled:(BOOL)enable {
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

    if ([self respondsToSelector:@selector(nextVideo)]) // Earlier YouTube Music version
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

        NSString *URL = pickedThumbnail.URL;

        YTImageServiceImpl *imageService = [gimme() instanceForType:%c(YTImageService)];
        [imageService makeImageRequestWithURL:[NSURL URLWithString:URL] responseBlock:^(UIImage *image) {
            NSDictionary *metadata = [self serializeTrack:next image:image];
            sendNextTrackMetadata(metadata);
        } errorBlock:nil];
    } else {
        sendNextTrackMetadata(nil);
    }
}

%new
- (NSDictionary *)serializeTrack:(YTIPlaylistPanelVideoRenderer *)item image:(UIImage *)image {
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

%end


%ctor {
    if (initClient(&skipNext, &manualUpdate)) {
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

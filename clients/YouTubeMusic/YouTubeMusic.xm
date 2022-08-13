#import "YouTubeMusic.h"
#import "../CommonClients.h"
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <HBLog.h>


// This used to be able to retrieve it from GIMMe, but they changed that...
YTImageService *imageService = nil;

%hook YTImageService

- (id)init {
    return imageService = %orig;
}

%end

%hook QueueController
#define _self ((QueueController *)self)

%property (nonatomic, assign) int skipNextNotifyToken;
%property (nonatomic, assign) int manualUpdateNotifyToken;

- (void)commonInit {
    %orig;

    int skipNextNotifyToken;
    int manualUpdateNotifyToken;

    registerNotifyTokens(^(int _) {
            [_self skipNext];
        },
        ^(int _) {
            [_self fetchNextUp];
        },
        &skipNextNotifyToken,
        &manualUpdateNotifyToken);

    _self.skipNextNotifyToken = skipNextNotifyToken;
    _self.manualUpdateNotifyToken = manualUpdateNotifyToken;
}

/* This is necessary as it spawns two of these classes, one of which is
   deallocated shortly after. When the `manualUpdate` notification call
   comes, `self` is something entirely different which results in a crash. */
- (void)dealloc {
    notify_cancel(_self.skipNextNotifyToken);
    notify_cancel(_self.manualUpdateNotifyToken);

    %orig;
}

%group AddQueueItems_New
- (unsigned long long)addQueueItems:(NSArray *)items
                   numItemsToReveal:(long long)reveal
                            atIndex:(unsigned long long)index
             ignoreSelectedProperty:(BOOL)ignoreSelectedProperty {
    unsigned long long orig = %orig;

    if (index == _self.nextVideoIndex)
        [_self fetchNextUp];

    return orig;
}
%end

%group AddQueueItems_Old
- (unsigned long long)addQueueItems:(NSArray *)items
                   numItemsToReveal:(long long)reveal
                            atIndex:(unsigned long long)index {
    unsigned long long orig = %orig;

    if (index == _self.nextVideoIndex)
        [_self fetchNextUp];

    return orig;
}
%end

%group MoveItemAtIndexPath_Old
- (void)moveItemAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    %orig;

    if (from.row == _self.nextVideoIndex || to.row == _self.nextVideoIndex)
        [_self fetchNextUp];
}
%end

%group MoveItemAtIndexPath_New
- (void)moveItemAtIndexPath:(NSIndexPath *)from
                toIndexPath:(NSIndexPath *)to
              userTriggered:(BOOL)userTriggered {
    %orig;

    if (from.row == _self.nextVideoIndex || to.row == _self.nextVideoIndex)
        [_self fetchNextUp];
}
%end

%group RemoveVideoAtIndex
- (void)removeVideoAtIndex:(unsigned long long)index {
    %orig;

    if (index == _self.nextVideoIndex)
        [_self fetchNextUp];
}
%end

%group RemoveQueueItemAtIndex_Old
- (void)removeQueueItemAtIndex:(unsigned long long)index {
    %orig;

    if (index == _self.nextVideoIndex)
        [_self fetchNextUp];
}
%end

%group RemoveQueueItemAtIndex_New
- (void)removeQueueItemAtIndex:(unsigned long long)index
                 userTriggered:(BOOL)userTriggered {
    %orig;

    if (index == _self.nextVideoIndex)
        [_self fetchNextUp];
}
%end

%group AutoMix
- (void)automixController:(id)controller
        didRemoveRenderersAtIndexes:(NSIndexSet *)indexes {
    %orig;

    if ([indexes containsIndex:_self.nextVideoIndex])
        [_self fetchNextUp];
}

- (void)automixController:(id)controller
        didInsertRenderersAtIndexes:(NSIndexSet *)indexes
        response:(id)arg3 {
    %orig;

    if ([indexes containsIndex:_self.nextVideoIndex])
        [_self fetchNextUp];
}
%end

- (void)setAutoExtendPlaybackQueueEnabled:(BOOL)enable {
    %orig;

    [_self fetchNextUp];
}

- (void)updateMDXPlaybackOrder {
    %orig;

    [_self fetchNextUp];
}

%group PlayItemAtIndex_Old
- (void)playItemAtIndex:(unsigned long long)index
         autoPlaySource:(int)autoplay
            atStartTime:(double)starttime {
    %orig;

    [_self fetchNextUp];
}
%end

%group PlayItemAtIndex_New
- (void)playItemAtIndex:(unsigned long long)index
        autoPlaySource:(int)autoplay
        isPlaybackControllerInternalTransition:(BOOL)transition
        atStartTime:(double)starttime {
    %orig;

    [_self fetchNextUp];
}
%end

%new
- (void)fetchNextUp {
    YTIPlaylistPanelVideoRenderer *next;

    // Using an earlier YouTube Music version?
    if ([_self respondsToSelector:@selector(nextVideo)])
        next = _self.nextVideo;
    else
        next = [_self nextVideoWithAutoplay:[_self hasAutoplayVideo]];

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
        [imageService makeImageRequestWithURL:URL responseBlock:^(UIImage *image) {
            sendNextTrackMetadata([_self serializeTrack:next image:image]);
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

    if (_self.nowPlayingIndex + 1 == _self.queueCount)
        metadata[kSkippable] = @NO;

    return metadata;
}

%new
- (void)skipNext {
    NSUInteger index = _self.nextVideoIndex;
    if ([_self respondsToSelector:@selector(removeQueueItemAtIndex:)]) {
        [_self removeQueueItemAtIndex:index];
    } else if ([_self respondsToSelector:@selector(removeQueueItemAtIndex:userTriggered:)]) {
        [_self removeQueueItemAtIndex:index userTriggered:YES];
    } else if ([_self respondsToSelector:@selector(removeVideoAtIndex:)]) {
        [_self removeVideoAtIndex:index];
    }
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

        Class queueController = %c(YTQueueController);
        if (!queueController) {
            queueController = %c(YTMQueueController);
        }
        %init(QueueController = queueController);

        if ([queueController instancesRespondToSelector:@selector(playItemAtIndex:
                                                                  autoPlaySource:
                                                                  isPlaybackControllerInternalTransition:
                                                                  atStartTime:)]) {
            %init(PlayItemAtIndex_New);
        } else {
            %init(PlayItemAtIndex_Old);
        }

        if ([queueController instancesRespondToSelector:@selector(addQueueItems:
                                                                  numItemsToReveal:
                                                                  atIndex:
                                                                  ignoreSelectedProperty:)]) {
            %init(AddQueueItems_New);
        } else {
            %init(AddQueueItems_Old);
        }

        if ([queueController instancesRespondToSelector:@selector(removeQueueItemAtIndex:)]) {
            %init(RemoveQueueItemAtIndex_Old);
        } else if ([queueController instancesRespondToSelector:@selector(removeQueueItemAtIndex:userTriggered:)]) {
            %init(RemoveQueueItemAtIndex_New);
        } else if ([queueController instancesRespondToSelector:@selector(removeVideoAtIndex:)]) {
            %init(RemoveVideoAtIndex);
        }

        if ([queueController instancesRespondToSelector:@selector(moveItemAtIndexPath:toIndexPath:userTriggered:)]) {
            %init(MoveItemAtIndexPath_New);
        } else {
            %init(MoveItemAtIndexPath_Old);
        }

        if ([queueController instancesRespondToSelector:@selector(automixController:didRemoveRenderersAtIndexes:)]) {
            %init(AutoMix);
        }
    }
}

#import "TIDAL.h"
#import "../CommonClients.h"


%hook _TtC4WiMP16PlayQueueManager
%property (nonatomic, retain) WMPImageService *imageService;
%property (nonatomic, retain) _TtC4WiMP13PlayQueueItem *lastSentTrack;

- (id)init {
    self = %orig;
    self.imageService = [[%c(WMPImageService) alloc] init];

    return self;
}

/* This is called on next track, toggling shuffle,
   reordering, adding or removing to/from the queue. */
- (void)playQueueDidChange {
    %orig;

    [self fetchNextUp];
}

%new
- (void)manuallyUpdate {
    self.lastSentTrack = nil;
    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if (!self.nextItem)
        return sendNextTrackMetadata(nil);

    _TtC4WiMP13PlayQueueItem *item = self.nextItem;

    if ([item isEqual:self.lastSentTrack])
        return;

    self.lastSentTrack = item;
    NSDictionary *metadata = [self serializeTrack:item];
    sendNextTrackMetadata(metadata);
}

%new
- (NSDictionary *)serializeTrack:(_TtC4WiMP13PlayQueueItem *)item {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = item.title;
    metadata[kSubtitle] = item.artistTitle;

    UIImage *image = [self.imageService imageForAlbumId:@(item.albumId)
                                    withImageResourceId:item.imageResourceId
                                                   size:8];
    if (!image)
        image = [self.imageService getDefaultAlbumImageForSize:8];

    metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%new
- (void)skipNext {
    if (self.nextItem)
        [self removeItemAtIndex:self.currentPosition + 1];
}

%end


%ctor {
    if (shouldInitClient(kTIDALBundleID)) {
        registerNotify(^(int _) {
            [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] skipNext];
        },
        ^(int _) {
            [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] manuallyUpdate];
        });
        %init;
    }
}

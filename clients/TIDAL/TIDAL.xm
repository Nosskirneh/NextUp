#import "TIDAL.h"
#import "../../Common.h"


void skipNext(notificationArguments) {
    [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] skipNext];
}

void manualUpdate(notificationArguments) {
    [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] manuallyUpdate];
}

%hook _TtC4WiMP16PlayQueueManager
%property (nonatomic, retain) WMPImageService *imageService;
%property (nonatomic, retain) _TtC4WiMP13PlayQueueItem *lastSentTrack;

- (id)init {
    _TtC4WiMP16PlayQueueManager *orig = %orig;
    orig.imageService = [[%c(WMPImageService) alloc] init];

    return orig;
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

    UIImage *image = [self.imageService imageForAlbumId:@(item.albumId) withImageResourceId:item.imageResourceId size:8];
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

// This is called on next track, toggling shuffle, reordering, adding or removing to/from the queue.
%hook _TtC4WiMP15PlayQueueModule

- (void)playQueueDidChange:(id)arg1 {
    %orig;

    [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] fetchNextUp];
}

%end


%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return;

    registerApp();

    subscribe(&skipNext, skipNextID(bundleID));
    subscribe(&manualUpdate, manualUpdateID(bundleID));
}

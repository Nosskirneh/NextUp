#import "VOX.h"
#import "../../Common.h"

void skipNext(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSkipNext object:nil];
}

void manualUpdate(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kManualUpdate object:nil];
}

%hook VOXPlayerQueue

- (id)init {
    self = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(skipNext)
                                                 name:kSkipNext
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchNextUp)
                                                 name:kManualUpdate
                                               object:nil];

    return self;
}

- (void)queueDidChange {
    %orig;

    [self fetchNextUp];
}

%new
- (void)skipNext {
    VoxPlayableItem *next = [self nextPlayableItem];
    if (!next)
        return;

    [self removeItem:next];
}

%new
- (void)fetchNextUp {
    VoxPlayableItem *next = [self nextPlayableItem];
    if (!next)
        return sendNextTrackMetadata(nil);

    VOXImageFetcher *imageFetcher = [%c(VOXImageFetcher) fetcherURL:[NSURL URLWithString:next.artworkURL]];

    [[%c(HNKCache) sharedCache] fetchImageForFetcher:imageFetcher formatName:@"smallArtworkCache" success:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:next image:image];
        sendNextTrackMetadata(metadata);
    } failure:^() {
        NSDictionary *metadata = [self serializeTrack:next image:nil];
        sendNextTrackMetadata(metadata);
    }];
}

%new
- (NSDictionary *)serializeTrack:(VoxPlayableItem *)item image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = item.name;
    metadata[kSubtitle] = item.artist;

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    metadata[kSkipable] = @YES;
    return metadata;
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

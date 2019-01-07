#import "Music.h"
#import "../../Common.h"


void APMSkipNext(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPMSkipNext object:nil];
}

void APMManualUpdate(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPMManualUpdate object:nil];
}

%hook MPCMediaPlayerLegacyPlaylistManager

- (id)init {
    MPCMediaPlayerLegacyPlaylistManager *orig = %orig;
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(skipNext)
                                                 name:kAPMSkipNext
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(fetchNextUp)
                                                 name:kAPMManualUpdate
                                               object:nil];
    return orig;
}

- (void)player:(id)player currentItemDidChangeFromItem:(MPMediaItem *)from toItem:(MPMediaItem *)to {
    %orig;
    [self fetchNextUp];
}

- (void)queueFeederDidInvalidateRealShuffleType:(MPCModelQueueFeeder *)queueFeeder {
    %orig;
    [self fetchNextUp];
}

- (void)addPlaybackContext:(id)context toQueueWithInsertionType:(long long)type completionHandler:(queueFeederBlock)completion {
    queueFeederBlock block = ^(MPCModelQueueFeeder *queueFeeder) {
        completion(queueFeeder);
        [self fetchNextUp];
    };
    %orig(context, type, block);
}

- (void)moveItemAtPlaybackIndex:(long long)from toPlaybackIndex:(long long)to intoHardQueue:(BOOL)hardQueue {
    %orig;
    long nextIndex = [self currentIndex] + 1;
    if (from == nextIndex || to == nextIndex)
        [self fetchNextUp];
}

- (void)removeItemAtPlaybackIndex:(long long)index {
    %orig;
    long nextIndex = [self currentIndex] + 1;
    if (index == nextIndex)
        [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    NUMediaItem *next = [self metadataItemForPlaylistIndex:[self currentIndex] + 1];

    if (!next)
        next = [self metadataItemForPlaylistIndex:0];

    if (next)
        [self fetchNextUpItem:next withArtworkCatalog:[next artworkCatalogBlock]];
}

%new
- (void)skipNext {
    int nextIndex = [self currentIndex] + 1;
    if (![self metadataItemForPlaylistIndex:nextIndex]) {
        nextIndex = 0;

        if ([self currentIndex] == nextIndex)
            return [self fetchNextUp]; // This means we have no tracks left in the queue
    }

    [self removeItemAtPlaybackIndex:nextIndex];

    NUMediaItem *next = [self metadataItemForPlaylistIndex:nextIndex];
    if (next) 
        [self fetchNextUpItem:next withArtworkCatalog:[next artworkCatalogBlock]];
}

%new
- (NSDictionary *)serializeTrack:(NUMediaItem *)item image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    UIImage *artwork = image;

    if ([item isKindOfClass:%c(MPCModelGenericAVItem)])
        metadata[kTitle] = [item mainTitle];
    else if ([item isKindOfClass:%c(MPMediaItem)]) {
        metadata[kTitle] = item.title;

        if (!image)
            artwork = [item.artwork imageWithSize:ARTWORK_SIZE];
    }

    metadata[kSubtitle] = item.artist;

    metadata[kArtwork] = UIImagePNGRepresentation(artwork);
    return metadata;
}

%new
- (void)fetchNextUpItem:(MPMediaItem *)item withArtworkCatalog:(block)artworkBlock {
    MPArtworkCatalog *catalog = artworkBlock();

    [catalog setFittingSize:ARTWORK_SIZE];
    catalog.destinationScale = [UIScreen mainScreen].scale;

    [catalog requestImageWithCompletionHandler:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:item image:image];
        sendNextTrackMetadata(metadata);
    }];
}

%end


%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return;

    registerApp();

    subscribe(&APMSkipNext, kAPMSkipNext);
    subscribe(&APMManualUpdate, kAPMManualUpdate);
}

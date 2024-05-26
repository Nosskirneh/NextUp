#import "Music.h"
#import "../CommonClients.h"


static NSDictionary *serializeMediaItem(MPMediaItem<NUMediaItem> *item, UIImage *image) {
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

static void fetchNextUpMediaItem(MPMediaItem<NUMediaItem> *item, MPArtworkCatalog *catalog) {
    // Local track with no artwork?
    if (!catalog) {
        UIImage *image = [%c(MPPlaceholderArtwork) noArtPlaceholderImageForMediaType:1];
        NSDictionary *metadata = serializeMediaItem(item, image);
        sendNextTrackMetadata(metadata);
        return;
    }

    [catalog setFittingSize:ARTWORK_SIZE];
    catalog.destinationScale = [UIScreen mainScreen].scale;

    [catalog requestImageWithCompletionHandler:^(UIImage *image) {
        NSDictionary *metadata = serializeMediaItem(item, image);
        sendNextTrackMetadata(metadata);
    }];
}

%hook MPCMediaPlayerLegacyPlaylistManager

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

- (void)player:(id)player currentItemDidChangeFromItem:(MPMediaItem *)from toItem:(MPMediaItem *)to {
    %orig;
    [self fetchNextUp];
}

- (void)queueFeederDidInvalidateRealShuffleType:(MPCModelQueueFeeder *)queueFeeder {
    %orig;
    [self fetchNextUp];
}

- (void)addPlaybackContext:(id)context
  toQueueWithInsertionType:(long long)type
         completionHandler:(queueFeederBlock)completion {
    queueFeederBlock block = ^(MPCModelQueueFeeder *queueFeeder) {
        completion(queueFeeder);
        [self fetchNextUp];
    };
    %orig(context, type, block);
}

- (void)moveItemAtPlaybackIndex:(long long)from
                toPlaybackIndex:(long long)to
                  intoHardQueue:(BOOL)hardQueue {
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
    MPMediaItem<NUMediaItem> *next = [self metadataItemForPlaylistIndex:[self currentIndex] + 1];

    if (!next)
        return sendNextTrackMetadata(nil);

    fetchNextUpMediaItem(next, [next artworkCatalogBlock]());
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

    MPMediaItem<NUMediaItem> *next = [self metadataItemForPlaylistIndex:nextIndex];
    if (next)
        fetchNextUpMediaItem(next, [next artworkCatalogBlock]());
}

%end


%ctor {
    if (shouldInitClient(Music)) {
        registerNotify(^(int _) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSkipNext object:nil];
        },
        ^(int _) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kManualUpdate object:nil];
        });
        %init;
    }
}

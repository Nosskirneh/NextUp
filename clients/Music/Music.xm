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


%group iOS13
    %hook MPCQueueController

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

    %new
    - (MPMediaItem<NUMediaItem> *)nu_nextItem {
        NSArray *items = [self nu_getQueue];
        if (!items || items.count < 1)
            return nil;

        return items[0];
    }

    %new
    - (void)fetchNextUp {
        MPMediaItem<NUMediaItem> *next = [self nu_nextItem];
        if (!next)
            return sendNextTrackMetadata(nil);

        fetchNextUpMediaItem(next, [next artworkCatalogBlock]());
    }

    %new
    - (void)skipNext {
        MPMediaItem<NUMediaItem> *next = [self nu_nextItem];
        if (!next)
            return;

        NSString *nextContentItemID = next.contentItemID;
        [self removeContentItemID:nextContentItemID completion:^{
            [self fetchNextUp];
        }];
    }

    - (void)queueCoordinatorDidChangeItems:(MPAVQueueCoordinator *)coordinator {
        %orig;

        [self fetchNextUp];
    }

    %new
    - (NSArray *)nu_getQueue {
        NSUInteger currentIndex = 0;
        NSEnumerator *enumerator = [self.identifierList enumeratorWithOptions:0];
        NSMutableArray *items = [NSMutableArray new];
        MPSectionedIdentifierListItemEntry *entry;
        while ((entry = enumerator.nextObject)) {
            NSArray *pair = @[entry.sectionIdentifier, entry.itemIdentifier];
            MPMediaItem<NUMediaItem> *item = [self _itemForPair:pair];

            if ([item.contentItemID isEqualToString:self.currentItem.contentItemID]) {
                currentIndex = (items.count - 1);
                continue;
            } else if (currentIndex == 0) {
                continue;
            }

            if (item)
                [items addObject:item];
        }

        return items;
    }

    %end
%end


%group iOS12
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

    - (void)player:(id)player
            currentItemDidChangeFromItem:(MPMediaItem *)from
            toItem:(MPMediaItem *)to {
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
%end


%ctor {
    if (shouldInitClient(kMusicBundleID)) {
        registerNotify(^(int _) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSkipNext object:nil];
        },
        ^(int _) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kManualUpdate object:nil];
        });
        %init;

        if (%c(MPCMediaPlayerLegacyPlaylistManager))
            %init(iOS12);
        else
            %init(iOS13);
    }
}

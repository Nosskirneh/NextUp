#import "Music.h"
#import "../CommonClients.h"


void skipNext(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSkipNext object:nil];
}

void manualUpdate(notificationArguments) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kManualUpdate object:nil];
}


static NSDictionary *serializeTrack(NUMediaItem *item, UIImage *image) {
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

static void fetchNextUpItem(NUMediaItem *item, block artworkBlock) {
    MPArtworkCatalog *catalog = artworkBlock();

    // Local track with no artwork?
    if (!catalog) {
        UIImage *image = [%c(MPPlaceholderArtwork) noArtPlaceholderImageForMediaType:1];
        NSDictionary *metadata = serializeTrack(item, image);
        sendNextTrackMetadata(metadata);
        return;
    }

    [catalog setFittingSize:ARTWORK_SIZE];
    catalog.destinationScale = [UIScreen mainScreen].scale;

    [catalog requestImageWithCompletionHandler:^(UIImage *image) {
        NSDictionary *metadata = serializeTrack(item, image);
        sendNextTrackMetadata(metadata);
    }];
}


%group iOS13
    %hook MPAVQueueCoordinator

    %new
    - (NUMediaItem *)nextItem {
        NSArray *items = self.items;
        if (!items || items.count < 2)
            return nil;

        return items[1];
    }

    %new
    - (void)fetchNextUp {
        NUMediaItem *next = [self nextItem];
        if (!next)
            return sendNextTrackMetadata(nil);

        fetchNextUpItem(next, [next artworkCatalogBlock]);
    }

    /* 7 is the magic number.
       This is done as it otherwise just has the next track in the queue.
       If users switch quickly, NextUp will send an empty queue message
       which will cause the media widget to hide and show very often. */
    - (unsigned long long)_preferredQueueDepthWithFirstItem:(id)firstItem {
        return 7;
    }

    %end


    %hook MPCQueueController

    - (id)init {
        self = %orig;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(skipNext)
                                                     name:kSkipNext
                                                   object:nil];
        return self;
    }

    - (void)setQueueCoordinator:(MPAVQueueCoordinator *)coordinator {
        %orig;

        [[NSNotificationCenter defaultCenter] addObserver:coordinator
                                                 selector:@selector(fetchNextUp)
                                                     name:kManualUpdate
                                                   object:nil];
    }

    %new
    - (void)skipNext {
        NUMediaItem *next = [self.queueCoordinator nextItem];
        if (!next)
            return;

        NSString *nextContentItemID = next.contentItemID;
        [self removeContentItemID:nextContentItemID completion:^{
            [self.queueCoordinator fetchNextUp];
        }];
    }

    - (void)queueCoordinatorDidChangeItems:(MPAVQueueCoordinator *)coordinator {
        %orig;

        [coordinator fetchNextUp];
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
        NUMediaItem *next = [self metadataItemForPlaylistIndex:[self currentIndex] + 1];

        if (!next)
            return sendNextTrackMetadata(nil);

        fetchNextUpItem(next, [next artworkCatalogBlock]);
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
            fetchNextUpItem(next, [next artworkCatalogBlock]);
    }

    %end
%end


%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!initClient(bundleID, &skipNext, &manualUpdate))
        return;

    if (%c(MPCMediaPlayerLegacyPlaylistManager))
        %init(iOS12);
    else
        %init(iOS13);
}

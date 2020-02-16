#import "VOX.h"
#import "../CommonClients.h"


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

    [[%c(HNKCache) sharedCache] fetchImageForFetcher:imageFetcher
                                          formatName:@"smallArtworkCache"
                                             success:^(UIImage *image) {
        sendNextTrackMetadata([self serializeTrack:next image:image]);
    } failure:^() {
        sendNextTrackMetadata([self serializeTrack:next image:nil]);
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
    if (shouldInitClient(kVOXBundleID)) {
        registerNotify(^(int _) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSkipNext object:nil];
        },
        ^(int _) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kManualUpdate object:nil];
        });
        %init;
    }
}

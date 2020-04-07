#import "Deezer.h"
#import "../CommonClients.h"


static DZRPlaybackQueuer *getQueuer() {
    return [%c(DZRAudioPlayer) sharedPlayer].queuer;
}

// Changing from a playlist to Flow doesn't automatically call setCurrentTrackIndex.
// This will make it fetch tracks when starting Flow.
%hook DZRMyMusicShuffleQueuer

- (void)setTracks:(NSArray *)tracks {
    %orig;

    [self fetchNextUp];
}

%end

%hook DZRPlaybackQueuer

- (void)setCurrentTrackIndex:(NSUInteger)index {
    %orig;

    [self fetchNextUp];
}

- (void)resetTrackIndex {
    %orig;

    [self fetchNextUp];
}

- (void)clearQueue {
    %orig;

    [self fetchNextUp];
}

- (void)replacePlayables:(id)arg1
       shuffledTracksIDs:(id)arg2
       currentTrackIndex:(unsigned long long)index {
    %orig;

    if (index == self.currentTrackIndex + 1)
        [self fetchNextUp];
}

- (void)removePlayableAtIndex:(unsigned long long)index {
    %orig;

    if (index == self.currentTrackIndex + 1)
        [self fetchNextUp];
}

- (void)movePlayableAtIndex:(unsigned long long)from
                    toIndex:(unsigned long long)to {
    %orig;

    if (from == self.currentTrackIndex + 1 ||
        to == self.currentTrackIndex + 1)
        [self fetchNextUp];
}

- (void)insertPlayables:(id)arg1 atIndex:(unsigned long long)index {
    %orig;

    if (index == self.currentTrackIndex + 1)
        [self fetchNextUp];
}

- (void)addPlayables:(id)arg1 {
    %orig;

    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if ([self.tracks count] <= self.currentTrackIndex + 1)
        return;

    DeezerTrack *track = self.tracks[self.currentTrackIndex + 1];
    [track fetchNowPlayingArtworkWithCompletion:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:track image:image];
        sendNextTrackMetadata(metadata);
    }];
}

%new
- (void)skipNext {
    int nextIndex = self.currentTrackIndex + 1;
    if ([self respondsToSelector:@selector(shuffledTracks)]) {
        // DZRBasicQueuer
        [self removePlayableAtIndex:nextIndex];
    } else {
        NSMutableArray *newTracks = [self.tracks mutableCopy];
        [newTracks removeObjectAtIndex:nextIndex];
        MSHookIvar<NSArray *>(self, "_tracks") = newTracks;
    }

    if ([self respondsToSelector:@selector(fetchMoreTracksIfNeededAfterSelectTrackAtIndex:)])
        [((DZRMixQueuer *)self) fetchMoreTracksIfNeededAfterSelectTrackAtIndex:self.currentTrackIndex];

    [self fetchNextUp];
}

%new
- (NSDictionary *)serializeTrack:(DeezerTrack *)track image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = track.title;
    metadata[kSubtitle] = track.artistName;
    // `nowPlayingArtwork` has to be fetched. It doesn't exist a method to do that
    // with a completionhandler, so I've implemented this in DeezerTrack below
    if (!image)
        image = [track.nowPlayingArtwork imageWithSize:ARTWORK_SIZE];

    metadata[kArtwork] = UIImagePNGRepresentation(image);
    return metadata;
}

%end


%hook DeezerTrack

%new
- (void)fetchNowPlayingArtworkWithCompletion:(void (^)(UIImage *))completion {
    NSArray *illustrations = [self illustrations];
    _TtC6Deezer18DeezerIllustration *illustration = [illustrations firstObject];

    [%c(_TtC6Deezer19IllustrationManager) fetchImageFor:illustration
                                                   size:ARTWORK_SIZE
                                                 effect:nil
                                                success:^(_TtC6Deezer18DeezerIllustration *illustration,
                                                          UIImage *image) {
                                                    completion(image);
                                              } failure:nil];
}

%end


%ctor {
    if (shouldInitClient(kDeezerBundleID)) {
        registerNotify(^(int _) {
            [getQueuer() skipNext];
        },
        ^(int _) {
            [getQueuer() fetchNextUp];
        });
        %init;
    }
}

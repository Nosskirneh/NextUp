#import "Deezer.h"
#import "../../Common.h"


void DZRSkipNext(notificationArguments) {
    [getMixQueuer() skipNext];
}

void DZRManualUpdate(notificationArguments) {
    [getMixQueuer() fetchNextUp];
}

DZRMixQueuer *getMixQueuer() {
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

%hook DZRMixQueuer

- (void)setCurrentTrackIndex:(NSUInteger)index {
    %orig;

    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if (self.tracks.count <= self.currentTrackIndex + 1)
        return;

    DeezerTrack *track = self.tracks[self.currentTrackIndex + 1];
    [track fetchNowPlayingArtworkWithCompletion:^(id image) {
        NSDictionary *metadata = [self serializeTrack:track image:image];
        sendNextTrackMetadata(metadata);
    }];
}

%new
- (void)skipNext {
    NSMutableArray *newTracks = [self.tracks mutableCopy];
    [newTracks removeObjectAtIndex:self.currentTrackIndex + 1];
    self.tracks = newTracks;

    [self fetchMoreTracksIfNeededAfterSelectTrackAtIndex:self.currentTrackIndex];

    [self fetchNextUp];
}

%new
- (NSDictionary *)serializeTrack:(DeezerTrack *)track image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = track.title;
    metadata[kSubtitle] = track.artistName;
    UIImage *artwork = image;
    // `nowPlayingArtwork` has to be fetched. It doesn't exist a method to do that
    // with a completionhandler, so I've implemented this in DeezerTrack below
    if (!artwork)
        artwork = [track.nowPlayingArtwork imageWithSize:ARTWORK_SIZE];
    metadata[kArtwork] = UIImagePNGRepresentation(artwork);
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
                                                success:^(_TtC6Deezer18DeezerIllustration *illustration, UIImage *image) {
                                                    completion(image);
                                              } failure:nil];
}

%end


%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return;

    registerApp();

    subscribe(&DZRSkipNext, kDZRSkipNext);
    subscribe(&DZRManualUpdate, kDZRManualUpdate);
}

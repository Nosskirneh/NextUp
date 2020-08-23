#import "Napster.h"
#import "../CommonClients.h"


static RHPlayerController *getPlayerController() {
    return [%c(RHAppDelegateRouter) appDelegate].playerController;
}

%hook RHPlayerController

- (void)toggleShuffle {
    %orig;

    [self fetchNextUp];
}

- (void)updateNowPlayingState {
    %orig;

    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    [self sendNextUpMetadata:self.nextItem.playableEntity.playableTrack];
}

%new
- (void)sendNextUpMetadata:(RHTrackMO *)track {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = track.name;
    metadata[kSubtitle] = track.artist.name;
    metadata[kSkippable] = @NO;

    UIImage *image = [self.imageProvider imageForAlbum:track.album
                                                  size:ARTWORK_SIZE
                                        usePlaceholder:NO
                                               promise:nil];
    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);
    sendNextTrackMetadata(metadata);
}

%end

%ctor {
    if (shouldInitClient(Napster)) {
        registerNotify(NULL, ^(int _) {
            [getPlayerController() fetchNextUp];
        });
        %init;
    }
}

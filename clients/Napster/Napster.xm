#import "Napster.h"
#import "../CommonClients.h"

RHPlayerController *getPlayerController() {
    return [%c(RHAppDelegateRouter) appDelegate].playerController;
}

void manualUpdate(notificationArguments) {
    [getPlayerController() fetchNextUp];
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
    %log;
    [self sendNextUpMetadata:self.nextItem.playableEntity.playableTrack];
}

%new
- (void)sendNextUpMetadata:(RHTrackMO *)track {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = track.name;
    metadata[kSubtitle] = track.artist.name;
    metadata[kSkipable] = @NO;

    UIImage *image = [self.imageProvider imageForAlbum:track.album size:ARTWORK_SIZE usePlaceholder:NO promise:nil];
    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);
    sendNextTrackMetadata(metadata);
}

%end

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!initClient(bundleID, NULL, &manualUpdate))
        return;
}

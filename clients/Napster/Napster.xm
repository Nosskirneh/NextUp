#import "Napster.h"
#import "../CommonClients.h"

RHPlayerController *getPlayerController() {
    return [%c(RHAppDelegateRouter) appDelegate].playerController;
}

// void skipNext(notificationArguments) {
//     [getPlayerController() skipNext];
// }

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

// Can't get this to work
// %new
// - (void)skipNext {
//     %log;

//     RHPlayerCachingController *cachingController = self.audioPlayerWrapper.playerCachingController;
//     NSMutableArray *newNext = [cachingController.nextPlayables mutableCopy];
//     [newNext removeObjectAtIndex:0];

//     NSMutableArray *newOld = [cachingController.playableCacheItems mutableCopy];
//     [newNext removeObjectAtIndex:0];

//     [[cachingController class] reuseOrCreateNewPlayableCacheItemsForPlayables:newNext oldPlaybleCacheItems:newOld];

//     MSHookIvar<NSArray *>(cachingController, "_nextPlayables") = newNext;
// }

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
    if (!initClient(bundleID))
        return;

    // subscribe(&skipNext, skipNextID(bundleID));
    subscribe(&manualUpdate, manualUpdateID(bundleID));
}

#import "Spotify.h"
#import "../../Common.h"
#import <substrate.h>

void SPTSkipNext(notificationArguments) {
    [getQueueImplementation() skipNext];
}

void SPTManualUpdate(notificationArguments) {
    SPTQueueViewModelImplementation *queueViewModel = getQueueImplementation();
    if (!queueViewModel)
        return;
    [queueViewModel fetchNextUp];
}

SpotifyApplication *getSpotifyApplication() {
    return (SpotifyApplication *)[UIApplication sharedApplication];
}

NowPlayingFeatureImplementation *getRemoteDelegate() {
    return getSpotifyApplication().remoteControlDelegate;
}

SPTQueueServiceImplementation *getQueueService() {
    return getRemoteDelegate().queueService;
}

SPTQueueViewModelImplementation *getQueueImplementation() {
    return getRemoteDelegate().queueInteractor.target;
}

// Fetch next track on app launch
%hook SPBarViewController

- (void)viewDidLoad {
    %orig;

    // Load image loader
    SPTQueueViewModelImplementation *queueViewModel = getQueueImplementation();
    queueViewModel.imageLoader = [getQueueService().glueImageLoaderFactory createImageLoaderForSourceIdentifier:@"se.nosskirneh.nextup"];

    // Add observer (otherwise this is only done as late as when opening the now playing view)
    SPTPlayerImpl *player = MSHookIvar<SPTPlayerImpl *>(queueViewModel, "_player");
    [player addPlayerObserver:queueViewModel];

    // This will fill the dataSource's futureTracks, which makes it possible to skip tracks
    [queueViewModel enableUpdates];
}

%end


%hook SPTQueueViewModelImplementation

%property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;
%property (nonatomic, retain) SPTPlayerTrack *lastSentTrack;

- (void)player:(SPTPlayerImpl *)player stateDidChange:(SPTPlayerState *)newState fromState:(SPTPlayerState *)oldState {
    %orig;

    [self fetchNextUpForState:newState];
}

%new
- (void)fetchNextUp {
    SPTPlayerImpl *player = MSHookIvar<SPTPlayerImpl *>(self, "_player");
    self.lastSentTrack = nil;
    [self fetchNextUpForState:player.state];
}

%new
- (void)fetchNextUpForState:(SPTPlayerState *)state {
    NSArray<SPTPlayerTrack *> *next = state.future;
    if (next.count > 0) {
        if (![next[0] isEqual:self.lastSentTrack])
            [self sendNextUpMetadata:next[0]];
        return;
    }
    
    sendNextTrackMetadata(nil);
}

%new
- (void)skipNext {
    if (!self.dataSource.futureTracks || self.dataSource.futureTracks.count == 0)
        return;

    SPTQueueTrackImplementation *track = self.dataSource.futureTracks[0];
    NSSet *tracks = [NSSet setWithArray:@[track]];
    [self removeTracks:tracks];
}

%new
- (void)sendNextUpMetadata:(SPTPlayerTrack *)track {
    self.lastSentTrack = track;

    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = [track trackTitle];
    metadata[kSubtitle] = track.artistTitle;

    // Artwork
    CGSize imageSize = ARTWORK_SIZE;
    __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

    // Do this lastly
    if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
        [self.imageLoader loadImageForURL:track.coverArtURL imageSize:imageSize completion:^(UIImage *img) {
            if (img)
                image = img;

            metadata[kArtwork] = UIImagePNGRepresentation(image);
            sendNextTrackMetadata(metadata);
        }];
    }
}

%end

%hook  SPTGaiaBackgroundController

- (void)player:(SPTPlayerImpl *)player stateDidChange:(SPTPlayerState *)newState fromState:(SPTPlayerState *)oldState {
    %orig;

    [getQueueImplementation() fetchNextUpForState:newState];
}

%end


%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return;

    registerApp();

    subscribe(&SPTSkipNext, kSPTSkipNext);
    subscribe(&SPTManualUpdate, kSPTManualUpdate);
}

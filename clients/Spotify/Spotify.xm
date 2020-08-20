#import "Spotify.h"
#import "../CommonClients.h"
#import <substrate.h>

static SPTNowPlayingServiceImplementation *nowPlayingService;

%hook SPTNowPlayingServiceImplementation

- (void)load {
    %orig;
    nowPlayingService = self;
}

- (void)unload {
    %orig;
    nowPlayingService = nil;
}

%end

static SPTQueueServiceImplementation *getQueueService() {
    return nowPlayingService.queueService;
}

static SPTQueueViewModelImplementation *getQueueImplementation() {
    return nowPlayingService.queueInteractor.target;
}

// Fetch next track on app launch
%hook SPBarViewController

- (void)viewDidLoad {
    %orig;

    // Load image loader
    SPTQueueViewModelImplementation *queueViewModel = getQueueImplementation();
    queueViewModel.imageLoader = [getQueueService().glueImageLoaderFactory
                                     createImageLoaderForSourceIdentifier:NEXTUP_IDENTIFIER];

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

- (void)player:(SPTPlayerImpl *)player
stateDidChange:(SPTPlayerState *)newState
     fromState:(SPTPlayerState *)oldState {
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
    NSArray *queue = nil;
    if (self.dataSource.futureTracks && self.dataSource.futureTracks.count > 0)
        queue = self.dataSource.futureTracks;
    else if (self.dataSource.upNextTracks && self.dataSource.upNextTracks.count > 0)
        queue = self.dataSource.upNextTracks;
    else
        return;

    NSSet *tracks = [NSSet setWithArray:@[queue[0]]];
    [self removeTracks:tracks];
}

%new
- (void)sendNextUpMetadata:(SPTPlayerTrack *)track {
    self.lastSentTrack = track;

    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = [track trackTitle];
    metadata[kSubtitle] = track.artistTitle;

    // Artwork
    __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

    // Do this lastly
    if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
        [self.imageLoader loadImageForURL:track.coverArtURL
                                imageSize:ARTWORK_SIZE
                               completion:^(UIImage *img) {
            if (img)
                image = img;

            metadata[kArtwork] = UIImagePNGRepresentation(image);
            sendNextTrackMetadata(metadata);
        }];
    }
}

- (void)disableUpdates {
    /* This gets called by the Spotify app itself in some cases.
       I have no idea why, but hooking it seems like a better
       idea compared to always calling `enableUpdates`. */
}

%end

%hook GaiaLocalAudioSessionController

- (void)player:(SPTPlayerImpl *)player
stateDidChange:(SPTPlayerState *)newState
     fromState:(SPTPlayerState *)oldState {
    %orig;

    [getQueueImplementation() fetchNextUpForState:newState];
}

%end


%ctor {
    if (shouldInitClient(Spotify)) {
        registerNotify(^(int _) {
            [getQueueImplementation() skipNext];
        },
        ^(int _) {
            SPTQueueViewModelImplementation *queueViewModel = getQueueImplementation();
            if (!queueViewModel)
                return;
            [queueViewModel fetchNextUp];
        });
        %init;
    }
}

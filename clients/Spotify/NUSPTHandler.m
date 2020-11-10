#import "Spotify.h"
#import "NUSPTHandler.h"
#import "../CommonClients.h"


@interface NUSPTHandler ()
@property (nonatomic, strong, readonly) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, strong) SPTPlayerTrack *lastSentTrack;

@property (nonatomic, strong, nullable) SPTPlayerState *currentState;
@end


@implementation NUSPTHandler

- (id)initWithImageLoader:(SPTGLUEImageLoader *)imageLoader {
    if (self == [super init]) {
        _imageLoader = imageLoader;

        int skipNextNotifyToken;
        int manualUpdateNotifyToken;

        registerNotifyTokens(^(int _) {
                [self skipNext];
            },
            ^(int _) {
                [self fetchNextUp];
            },
            &skipNextNotifyToken,
            &manualUpdateNotifyToken
        );
    }

    return self;
}

- (void)player:(id <SPTPlayer>)player stateDidChange:(SPTPlayerState *)newState fromState:(SPTPlayerState *)oldState {
    self.currentState = newState;
}

- (void)setCurrentState:(SPTPlayerState *)currentState {
    _currentState = currentState;
    [self fetchNextUpForState:currentState];
}

- (void)fetchNextUp {
    self.lastSentTrack = nil;
    [self fetchNextUpForState:self.currentState];
}

- (void)fetchNextUpForState:(SPTPlayerState *)state {
    NSArray<SPTPlayerTrack *> *next = state.future;
    if (next.count > 0) {
        if (![next[0] isEqual:self.lastSentTrack])
            [self sendNextUpMetadata:next[0]];
        return;
    }

    sendNextTrackMetadata(nil);
}

- (void)skipNext {
    SPTQueueViewModelImplementation *queueViewModel = self.queueViewModel;
    if (!queueViewModel) {
        return;
    }

    NSArray *queue = nil;
    if (queueViewModel.dataSource.futureTracks && queueViewModel.dataSource.futureTracks.count > 0)
        queue = queueViewModel.dataSource.futureTracks;
    else if (queueViewModel.dataSource.upNextTracks && queueViewModel.dataSource.upNextTracks.count > 0)
        queue = queueViewModel.dataSource.upNextTracks;
    else
        return;

    NSSet *tracks = [NSSet setWithArray:@[queue[0]]];
    [queueViewModel removeTracks:tracks];
}

- (void)sendNextUpMetadata:(SPTPlayerTrack *)track {
    self.lastSentTrack = track;

    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = [track trackTitle];
    metadata[kSubtitle] = track.artistTitle;
    metadata[kSkippable] = @(self.queueViewModel != nil);

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

@end

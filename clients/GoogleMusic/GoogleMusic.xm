#import "GoogleMusic.h"
#import "../CommonClients.h"


static AppDelegate *getGPMAppDelegate() {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

static GPMImageFetcher *getImageFetcher() {
    return getGPMAppDelegate().appServiceManager.imageFetcher;
}

static MusicQueueManager *getQueueManager() {
    return getGPMAppDelegate().musicQueueManager;
}

%hook MusicQueueManager
%property (nonatomic, retain) Track *lastSentTrack;

- (void)updatePlayState {
    %orig;

    [self fetchNextUp];
}

// This is called when reordering the queue, removing or adding something to/from it
- (void)updateCurrentTrackAndIndex {
    %orig;

    [self fetchNextUp];
}

%new
- (void)manuallyUpdate {
    self.lastSentTrack = nil;
    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if (!self.hasNext)
        return sendNextTrackMetadata(nil);

    Track *track = self.tracks[self.currentTrackIndex + 1];
    if ([track isEqual:self.lastSentTrack])
        return;

    self.lastSentTrack = track;

    NSURL *artworkURL = [NSURL URLWithString:track.albumArtURLString];
    [getImageFetcher() fetchImageWithURL:artworkURL
                                    size:ARTWORK_SIZE
                                 quality:1
                       operationSequence:[%c(GPMOperationSequence) new]
                       completionHandler:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:track image:image];
        sendNextTrackMetadata(metadata);
    }];
}

%new
- (NSDictionary *)serializeTrack:(Track *)track image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = track.title;
    metadata[kSubtitle] = track.albumArtistString;

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%new
- (void)skipNext {
    if (self.hasNext)
        [self removeTrackAtIndex:self.currentTrackIndex + 1];
}

%end


%ctor {
    if (shouldInitClient(kGoogleMusicBundleID)) {
        registerNotify(^(int _) {
            [getQueueManager() skipNext];
        },
        ^(int _) {
            [getQueueManager() manuallyUpdate];
        });
        %init;
    }
}

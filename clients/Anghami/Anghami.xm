#import "Anghami.h"
#import "../CommonClients.h"


static ANGPlayQueue *getQueue() {
    return [%c(PlayQueueSingleton) currentPlayQueue];
}

%hook ANGPlayQueue
%property (nonatomic, retain) ANGSong *lastSentTrack;

- (void)setIsShuffled:(BOOL)shuffle keepSameSong:(BOOL)keep {
    %orig;

    [self fetchNextUp];
}

// This seems to be called on all usable methods in PlayQueueSingleton (move, add, clear etc)
- (BOOL)setCurrentIndex:(unsigned long long)index
             userAction:(BOOL)userAction
                 report:(BOOL)report {
    BOOL orig = %orig;
    [self fetchNextUp];

    return orig;
}

%new
- (void)manuallyUpdate {
    self.lastSentTrack = nil;
    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if (!self.nextSong)
        return sendNextTrackMetadata(nil);

    ANGSong *item = self.nextSong;

    if ([item isEqual:self.lastSentTrack])
        return;

    self.lastSentTrack = item;


    ANGImageDownloadSpec *spec = [item imageDownloadSpecWithSize:ARTWORK_SIZE.width];
    ANGImageDownloader *imageDownloader = [%c(ANGImageDownloader) sharedInstance];
    [imageDownloader getImage:spec callback:^(void) {
        BOOL thumbnail = YES;
        UIImage *image = [imageDownloader imageFromCacheForSpec:spec
                                                      thumbnail:&thumbnail];
        NSDictionary *metadata = [self serializeTrack:item image:image];
        sendNextTrackMetadata(metadata);
    }];
}

%new
- (NSDictionary *)serializeTrack:(ANGSong *)item image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = item.title;
    metadata[kSubtitle] = item.artistName;

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%new
- (void)skipNext {
    if (self.nextSong)
        [%c(PlayQueueSingleton) removeSongFromQueue:self.nextSong];
}

%end


%ctor {
    if (shouldInitClient(Anghami)) {
        registerNotify(^(int _) {
            [getQueue() skipNext];
        },
        ^(int _) {
            [getQueue() manuallyUpdate];
        });
        %init;
    }
}

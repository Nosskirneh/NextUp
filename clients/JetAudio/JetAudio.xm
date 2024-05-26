#import "JetAudio.h"
#import "../CommonClients.h"


%hook JAudioPlayer

- (id)init {
    self = %orig;

    registerNotify(^(int _) {
            [self skipNext];
        },
        ^(int _) {
            [self fetchNextUp];
        });

    return self;
}

- (void)queueChanged {
    %orig;

    [self fetchNextUp];
}

- (void)notifyChangeTrackInfo:(int)track byEngine:(BOOL)engine {
    %orig;

    [self fetchNextUp];
}

- (void)playTrack:(int)track {
    %orig;

    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if ([self getNumTracks] == 0)
        return sendNextTrackMetadata(nil);

    NSArray *queue = [self getQueue];
    int nextIndex = [self getCurTrack] + 1;
    if (queue.count <= nextIndex)
        return sendNextTrackMetadata(nil);

    JMediaItem *nextItem = queue[nextIndex];
    NSDictionary *data = [self serializeSong:nextItem];

    sendNextTrackMetadata(data);
}

%new
- (void)skipNext {
    int count = [self getNumTracks];
    if (count == 0)
        return;

    int nextIndex = [self getCurTrack] + 1;
    if (count <= nextIndex)
        return;

    [self removeTrackWithTrack:nextIndex];
}

%new
- (NSDictionary *)serializeSong:(JMediaItem *)song {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = [song getTitle];
    metadata[kSubtitle] = [song getArtist];
    UIImage *image = [song getArtworkWithSize:ARTWORK_SIZE];
    if (!image)
        image = MSHookIvar<UIImage *>(self, "mDefArtwork");
    metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%end

%ctor {
    if (shouldInitClient(JetAudio))
        %init;
}

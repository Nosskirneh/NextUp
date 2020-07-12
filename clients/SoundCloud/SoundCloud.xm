#import "SoundCloud.h"
#import "../CommonClients.h"


%hook PlaybackService
%property (nonatomic, retain) _TtC2UI11ImageLoader *imageLoader;

%new
- (id)getImageLoader {
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        self.imageLoader = [%c(_TtC2UI11ImageLoader) makeForObjC];
    });
    return self.imageLoader;
}

- (void)preloadItemAfterItem:(id)arg1 {
    %orig;
    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    _TtC8Playback10PlayerItem *item = [self nextItemWithInteraction:0];

    if (!item)
        return;

    [[self getImageLoader] loadImageFrom:item.artworkURL
                       successCompletion:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:item
                                                image:image
                                             skipable:NO];
        sendNextTrackMetadata(metadata);
    } failureCompletion:nil];
}

%new
- (NSDictionary *)serializeTrack:(_TtC8Playback10PlayerItem *)item
                           image:(UIImage *)image
                        skipable:(BOOL)skipable {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = item.title;
    metadata[kSubtitle] = item.artistName;
    metadata[kSkipable] = @(skipable);

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%end


%ctor {
    if (shouldInitClient(SoundCloud)) {
        registerNotify(NULL, ^(int _) {
            [[%c(PlaybackService) sharedInstance] fetchNextUp];
        });
        %init;
    }
}

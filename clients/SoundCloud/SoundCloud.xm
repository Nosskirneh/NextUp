#import "SoundCloud.h"
#import "../CommonClients.h"


%hook PlaybackService
%property (nonatomic, retain) _TtC2UI11ImageLoader *imageLoader;

static inline _TtC2UI11ImageLoader *loadImageLoader() {
    Class imageLoaderClass = %c(_TtC2UI11ImageLoader);
    if ([imageLoaderClass respondsToSelector:@selector(makeForObjC)]) {
        return [imageLoaderClass makeForObjC];
    }
    return [objc_getClass("UI.ImageLoaderObjFactory") make];
}

%new
- (id)getImageLoader {
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        self.imageLoader = loadImageLoader();
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
                                             skippable:NO];
        sendNextTrackMetadata(metadata);
    } failureCompletion:nil];
}

%new
- (NSDictionary *)serializeTrack:(_TtC8Playback10PlayerItem *)item
                           image:(UIImage *)image
                        skippable:(BOOL)skippable {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = item.title;
    metadata[kSubtitle] = item.artistName;
    metadata[kSkippable] = @(skippable);

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

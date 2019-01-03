#import "SoundCloud.h"
#import "../../Common.h"

void SDCManualUpdate(notificationArguments) {
    [[%c(PlaybackService) sharedInstance] fetchNextUp];
}

%hook _TtC2UI11ImageLoader

- (id)initWithPlaceholder:(id)arg1 {
    PlaybackService *playbackService = [%c(PlaybackService) sharedInstance];
    if (!playbackService.imageLoader)
        return playbackService.imageLoader = %orig;
    return %orig;
}

%end

%hook PlaybackService
%property (nonatomic, retain) _TtC2UI11ImageLoader *imageLoader;

- (void)preloadItemAfterItem:(id)arg1 {
    %orig;
    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    _TtC8Playback10PlayerItem *item = [self nextItemWithInteraction:0];

    if (!item)
        return;

    [self.imageLoader loadImageFrom:item.artworkURL successCompletion:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:item image:image skipable:NO];
        sendNextTrackMetadata(metadata);
    } failureCompletion:nil];
}

%new
- (NSDictionary *)serializeTrack:(_TtC8Playback10PlayerItem *)item image:(UIImage *)image skipable:(BOOL)skipable {
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
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (preferences[bundleID] && ![preferences[bundleID] boolValue])
        return;

    registerApp();

    subscribe(&SDCManualUpdate, kSDCManualUpdate);
}

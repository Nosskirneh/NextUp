#import "Podcasts.h"
#import "../CommonClients.h"


%hook MTAppDelegate_Shared

- (BOOL)application:(id)arg didFinishLaunchingWithOptions:(id)options {
    // This makes sure its init method gets called
    [%c(MTPlaybackQueueController) sharedInstance];
    return %orig;
}

%end

%hook MTPlaybackQueueController
%property (nonatomic, retain) MTPlayerItem *lastSentEpisode;

- (id)init {
    MTPlaybackQueueController *orig = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(fetchNextUp)
                                                 name:@"IMPlayerManifestDidChange"
                                               object:nil];
    return orig;
}

%new
- (NSDictionary *)serializeTrack:(MTPlayerItem *)item
                           image:(UIImage *)image
                        skippable:(BOOL)skippable {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = item.title;
    metadata[kSubtitle] = item.subtitle;
    metadata[kSkippable] = @(skippable);

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%new
- (MTCompositeManifest *)getManifest {
    if ([self respondsToSelector:@selector(manifest)])
        return self.manifest;
    else if ([self respondsToSelector:@selector(compositeManifest)])
        return self.compositeManifest;
    return nil;
}

%new
- (void)manuallyUpdate {
    self.lastSentEpisode = nil;
    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    MTCompositeManifest *manifest = [self getManifest];

    MTPlayerItem *item = nil;
    int nextIndex = manifest.currentIndex + 1;
    if (manifest.currentIndex == LONG_MAX)
        nextIndex = 1;

    if ([manifest count] > nextIndex) {
        BOOL skippable = manifest.upNextManifest.count > 0 &&
                        !(manifest.upNextManifest.count == 1 && manifest.isPlayingFromUpNext);
        item = [manifest objectAtIndex:nextIndex];
        [self fetchNextUpFromItem:item skippable:skippable];
    } else {
        sendNextTrackMetadata(nil);
    }
    self.lastSentEpisode = item;
}

%new
- (void)fetchNextUpFromItem:(MTPlayerItem *)item skippable:(BOOL)skippable {
    // Since manual updates are coming from SpringBoard when the
    // current now playing app changed to Podcasts, this would otherwise
    // happen twice (due to the IMPlayerManifestDidChange notification).
    if ([self.lastSentEpisode isEqual:item])
        return;

    [item retrieveArtwork:^(UIImage *image) {
        NSDictionary *metadata = [self serializeTrack:item image:image skippable:skippable];
        sendNextTrackMetadata(metadata);
    } withSize:ARTWORK_SIZE];
}

%new
- (void)skipNext {
    MTCompositeManifest *manifest = [self getManifest];
    int nextIndex = manifest.currentIndex + 1;
    if ([manifest count] > nextIndex) {
        // This only work with items that were manually queued;
        // seems to be a limiation in how the Podcasts app is built.
        BOOL removed = NO;
        if ([self respondsToSelector:@selector(nowPlayingInfoCenter:removeItemAtOffset:)]) {
            MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter infoCenterForPlayerID:@"Podcasts"];
            removed = [self nowPlayingInfoCenter:infoCenter removeItemAtOffset:nextIndex];
        } else if ([self respondsToSelector:@selector(removeItemWithContentID:)]) {
            MTPlayerItem *item = [manifest objectAtIndex:nextIndex];
            removed = [self removeItemWithContentID:[item contentItemIdentifier]];
        }

        if (removed)
            [self fetchNextUp];
    }
}

%end


%ctor {
    if (shouldInitClient(Podcasts)) {
        registerNotify(^(int _) {
            [[%c(MTPlaybackQueueController) sharedInstance] skipNext];
        },
        ^(int _) {
            MTPlaybackQueueController *queueController = [%c(MTPlaybackQueueController) sharedInstance];
            queueController.lastSentEpisode = nil;
            [queueController fetchNextUp];
        });
        %init;
    }
}

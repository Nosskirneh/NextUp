#import "Musi.h"
#import "../CommonClients.h"

MMusicSession *getMusicSession() {
    MSplashViewController *splashViewController = (MSplashViewController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
    return splashViewController.mainViewController.nowPlayingViewController.session;
}

void skipNext(notificationArguments) {
    [getMusicSession() skipNext];
}

void manualUpdate(notificationArguments) {
    [getMusicSession() fetchNextUp];
}

%hook MMusicSession

%property (nonatomic, retain) MTrack *lastSentTrack;

// This seems to get called a for every pause and play too. For that reason,
// I'm using lastSentTrack to only send new next tracks.
- (void)updateNowPlayingCenterWithInfo:(id)info {
    %orig;

    [self fetchNextUp];
}

// Changes shuffle/repeat mode
- (void)musicControllerSettingsDidChangeMode:(MMusicControllerSettings *)settings {
    %orig;

    [self fetchNextUp];
}

- (void)musicControllerDidChangeUpNextQueue:(id)queue sender:(id)controller {
    %orig;

    [self fetchNextUp];
}

%new
- (BOOL)isShuffling {
    return self.settings.mode == 2;
}

%new
- (void)skipNext {
    if (!self.hasNextTrack)
        return;

    MMusicSessionTrackProviderSource *provider = self.currentTrackProviderSource;
    if (provider.playlistProvider) {
        [self isShuffling] ? [provider.playlistProvider fetchNextTrackShuffle] :
                             [provider.playlistProvider fetchNextTrackLinearWithTrack:self.currentMusicTrack.track];
    } else {
        [provider.mixProvider fetchNextTrack];
    }

    [self fetchNextUp];
}

%new
- (void)fetchNextUp {
    if (!self.hasNextTrack)
        return sendNextTrackMetadata(nil);

    MTrack *next = [self peekNextTrack];
    if ([next isEqual:self.lastSentTrack])
        return;

    self.lastSentTrack = next;
    NSURL *url = next.thumbnailSmallURL;
    UIImage *image = [[%c(SDImageCache) sharedImageCache] imageFromDiskCacheForKey:url.absoluteString];
    if (!image) {
        [[%c(SDWebImageManager) sharedManager] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage *image, NSError *error, NSURL *url) {
            NSDictionary *metadata = [self serializeTrack:next image:image];
            sendNextTrackMetadata(metadata);
        }];
    } else {
        NSDictionary *metadata = [self serializeTrack:next image:image];
        sendNextTrackMetadata(metadata);
    }
}

%new
- (NSDictionary *)serializeTrack:(MTrack *)item image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    metadata[kTitle] = item.name;
    metadata[kSubtitle] = item.creator;

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    metadata[kSkipable] = @YES;
    return metadata;
}

%end


%ctor {
    if (initClient(&skipNext, &manualUpdate))
        %init;
}

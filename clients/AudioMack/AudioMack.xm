#import "AudioMack.h"
#import "../CommonClients.h"

#define kSongChanged @"songChanged"

/* For testing only */
// %hook PremiumRepository

// - (BOOL)isPremium {
//     return YES;
// }

// %end

%hook AMNowPlayingViewController

- (void)movedSongFromIndex:(NSInteger)from toIndex:(NSInteger)to {
    %orig;

    int nextIndex = self.lookupIndex + 1;
    if (from == nextIndex || to == nextIndex)
        [self fetchNextUp];
}

- (void)removeSongAtIndex:(NSInteger)index {
    %orig;

    if (index == self.lookupIndex + 1)
        [self fetchNextUp];
}

- (void)playSongAtIndex:(long long)index {
    %orig;

    [self fetchNextUp];
}

- (void)playItem:(Item *)item {
    %orig;

    [self fetchNextUp];
}

- (void)playNext {
    %orig;

    [self fetchNextUp];
}

- (void)playURL:(NSURL *)URL forID:(id)ID {
    %orig;

    [self fetchNextUp];
}

- (void)playLocalSong:(Item *)song localURL:(NSURL *)URL {
    %orig;

    [self fetchNextUp];
}

- (void)playPrev:(BOOL)previous {
    %orig;

    [self fetchNextUp];
}

- (void)toggleShuffle {
    %orig;

    [self fetchNextUp];
}

- (void)addSong:(Item *)song atIndex:(NSInteger)index {
    %orig;

    if (index == self.lookupIndex + 1)
        [self fetchNextUp];
}

%new
- (void)skipNext {
    if ([self queue].count == 0)
        return;

    [self removeSongAtIndex:self.lookupIndex + 1];
    // This will update the queue table view
    [[NSNotificationCenter defaultCenter] postNotificationName:kSongChanged object:nil];
}

%new
- (NSDictionary *)serializeSong:(Item *)song image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = song.title;
    metadata[kSubtitle] = song.artist;

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%new
- (void)fetchNextUp {
    if ([self queue].count == 0)
        return sendNextTrackMetadata(nil);

    Item *song = [self songAtIndex:self.lookupIndex + 1];
    if (!song)
        return sendNextTrackMetadata(nil);

    // Get image
    NSString *imageURLString = song.image;
    UIImage *image = [[%c(SDImageCache) sharedImageCache] imageFromDiskCacheForKey:imageURLString];
    if (!image) {
        SDWebImageManager *imageManager = [%c(SDWebImageManager) sharedManager];
        id completion = ^(UIImage *image, NSError *error, NSURL *url) {
            sendNextTrackMetadata([self serializeSong:song image:image]);
        };

        if ([imageManager respondsToSelector:@selector(downloadImageWithURL:options:progress:completed:)])
            [imageManager downloadImageWithURL:[NSURL URLWithString:imageURLString]
                                       options:0
                                      progress:nil
                                     completed:completion];
        else if ([imageManager respondsToSelector:@selector(loadImageWithURL:options:progress:completed:)])
            [imageManager loadImageWithURL:[NSURL URLWithString:imageURLString]
                                   options:0
                                  progress:nil
                                 completed:completion];
    } else {
        sendNextTrackMetadata([self serializeSong:song image:image]);
    }
}

%end


%ctor {
    if (shouldInitClient(AudioMack)) {
        registerNotify(^(int _) {
            [[%c(AMNowPlayingViewController) sharedInstance] skipNext];
        },
        ^(int _) {
            [[%c(AMNowPlayingViewController) sharedInstance] fetchNextUp];
        });
        %init(/*PremiumRepository = objc_getClass("audiomack_iphone.PremiumRepository")*/);
    }
}

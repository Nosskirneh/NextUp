#import "JioSaavn.h"
#import "../CommonClients.h"


@interface NSString (Missing)
- (id)CDVStringByXMLUnquoting;
@end

PlayerVC *getPlayerVC() {
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] getPlayerVC];
}

void skipNext(notificationArguments) {
    [getPlayerVC() skipNext];
}

void manualUpdate(notificationArguments) {
    [getPlayerVC() fetchNextUp];
}

%hook PlayerVC

- (void)updateQueueWithoutChangingSong {
    %orig;

    [self fetchNextUp];
}

- (void)playSongAtIndex:(long long)arg1 {
    %orig;

    [self fetchNextUp];
}

- (void)shuffleTapped:(BOOL)arg1 {
    %orig;

    [self fetchNextUp];
}

%new
- (void)skipNext {
    if ([self isQueueEmpty])
        return;

    [self getNextSong:^(NSMutableDictionary *song) {
        int index = [[self getQueue] indexOfObject:song];
        [self removeSong:[NSIndexPath indexPathForRow:index inSection:1] fromTable:self.mainTable];
        [self fetchNextUp];
    }];
}

%new
- (NSDictionary *)serializeSong:(NSDictionary *)song image:(UIImage *)image {
    NSMutableDictionary *metadata = [NSMutableDictionary new];

    metadata[kTitle] = [song[@"title"] CDVStringByXMLUnquoting];
    metadata[kSubtitle] = [%c(SongUtil) getPrimaryArtistNamesForSong:song];

    if (image)
        metadata[kArtwork] = UIImagePNGRepresentation(image);

    return metadata;
}

%new
- (void)fetchNextUp {
    if ([self isQueueEmpty])
        return sendNextTrackMetadata(nil);

    [self getNextSong:^(NSDictionary *song) {
        if (!song)
            return sendNextTrackMetadata(nil);

        // Get image
        NSString *imageURLString = song[@"image"];
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
    }];
}

%end

%ctor {
    if (initClient(&skipNext, &manualUpdate))
        %init;
}

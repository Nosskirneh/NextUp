#import <MediaPlayer/MediaPlayer.h>

@interface MPPlaceholderArtwork : NSObject
+ (UIImage *)noArtPlaceholderImageForMediaType:(unsigned int)type;
@end


@interface NUMediaItem : MPMediaItem
@property (nonatomic, copy) NSString *contentItemID;
- (NSString *)mainTitle;
- (id)artworkCatalogBlock;
@end


@interface MPArtworkCatalog : NSObject
@property (nonatomic, readonly) BOOL hasImageOnDisk;
@property (assign, nonatomic) double destinationScale;
- (id)bestImageFromDisk;
- (void)requestImageWithCompletionHandler:(id)arg1;
- (void)setFittingSize:(CGSize)arg1;
@end

typedef MPArtworkCatalog *(^block)(void);


// iOS 13
@interface MPAVQueueCoordinator : NSObject
@property (nonatomic, readonly) NSArray *items;
- (NUMediaItem *)nextItem;
- (void)fetchNextUp;
@end

@interface MPCQueueController : NSObject
@property (nonatomic, retain) MPAVQueueCoordinator *queueCoordinator;
- (void)removeContentItemID:(NSString *)contentItemID
                 completion:(void(^)())completion;
@end
// ---


// iOS 12
@interface MPCMediaPlayerLegacyPlaylistManager
@property (assign, nonatomic) long long nextCurrentIndex;
- (void)removeItemAtPlaybackIndex:(long long)arg;
- (id)metadataItemForPlaylistIndex:(long long)arg;
- (long long)currentIndex;

- (void)fetchNextUp;
- (void)skipNext;
@end

@interface MPCModelQueueFeeder : NSObject
@end

typedef void (^queueFeederBlock)(MPCModelQueueFeeder *queueFeeder);
// ---

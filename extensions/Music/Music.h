#import <MediaPlayer/MediaPlayer.h>

@interface NUMediaItem : MPMediaItem
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


@interface MPCMediaPlayerLegacyPlaylistManager
@property (assign, nonatomic) long long nextCurrentIndex;
- (void)removeItemAtPlaybackIndex:(long long)arg;
- (id)metadataItemForPlaylistIndex:(long long)arg;
- (long long)currentIndex;

- (NSDictionary *)serializeTrack:(id)item image:(UIImage *)image;
- (void)fetchNextUp;
- (void)fetchNextUpItem:(id)item withArtworkCatalog:(block)artworkBlock;
- (void)skipNext;
@end

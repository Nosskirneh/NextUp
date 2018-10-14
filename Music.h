@interface MPArtworkCatalog : NSObject
@property (nonatomic,readonly) BOOL hasImageOnDisk;
@property (assign,nonatomic) double destinationScale;
- (id)bestImageFromDisk;
- (void)requestImageWithCompletionHandler:(id)arg1;
- (void)setFittingSize:(CGSize)arg1;
@end

typedef MPArtworkCatalog *(^block)(void);

@interface MPMusicPlayerController (Addition)
- (NSDictionary *)serializeTrack:(id)item image:(UIImage *)image;
- (id)nowPlayingItemAtIndex:(NSUInteger)arg1;
@end

@interface MPModelObjectMediaItem : MPMediaItem
@property (nonatomic, readonly) id modelObject;
@end

@interface MPModelSong : NSObject
- (id)valueForModelKey:(id)aa;
@end

@interface SBMediaController ()
- (void)handleNextUpModelObjectMediaItem:(MPMediaItem *)item;
@end

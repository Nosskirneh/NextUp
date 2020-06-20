#import <MediaPlayer/MediaPlayer.h>

@interface MPPlaceholderArtwork : NSObject
+ (UIImage *)noArtPlaceholderImageForMediaType:(unsigned int)type;
@end

@interface MPArtworkCatalog : NSObject
@property (nonatomic, readonly) BOOL hasImageOnDisk;
@property (assign, nonatomic) double destinationScale;
- (UIImage *)bestImageFromDisk;
- (void)requestImageWithCompletionHandler:(id)completion;
- (void)setFittingSize:(CGSize)size;
@end

typedef MPArtworkCatalog *(^catalogBlock)(void);

@protocol NUMediaItem
@optional
@property (nonatomic, copy) NSString *contentItemID;
- (NSString *)mainTitle;
- (catalogBlock)artworkCatalogBlock;
@end

@interface MPMediaItem (Extra) <NUMediaItem>
@end


// iOS 13
@interface MPSectionedIdentifierList : NSObject
- (NSEnumerator *)enumeratorWithOptions:(NSEnumerationOptions)options;
@end

@interface MPSectionedIdentifierListItemEntry : NSObject
@property (nonatomic, readonly) NSString *itemIdentifier;
@property (nonatomic, readonly) NSString *sectionIdentifier;
@end

@interface MPAVQueueCoordinator : NSObject
@end

@interface MPCQueueController : NSObject
@property (nonatomic, retain) MPSectionedIdentifierList *identifierList;
@property (nonatomic, readonly) MPMediaItem<NUMediaItem> *currentItem;
- (void)removeContentItemID:(NSString *)contentItemID
                 completion:(void(^)())completion;
- (id)_itemForPair:(NSArray *)pair;
- (NSArray *)nu_getQueue;
- (MPMediaItem<NUMediaItem> *)nu_nextItem;
- (void)fetchNextUp;
@end
// ---


// iOS 12
@interface MPCMediaPlayerLegacyPlaylistManager
@property (assign, nonatomic) long long nextCurrentIndex;
- (void)removeItemAtPlaybackIndex:(long long)index;
- (id)metadataItemForPlaylistIndex:(long long)index;
- (long long)currentIndex;

- (void)fetchNextUp;
- (void)skipNext;
@end

@interface MPCModelQueueFeeder : NSObject
@end

typedef void (^queueFeederBlock)(MPCModelQueueFeeder *queueFeeder);
// ---

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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

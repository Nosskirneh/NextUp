@interface RHQueuedItemMO  : NSObject
+ (id)dequeueItem:(id)arg1 andReturnDownloadedTrackWithoutLeaseInContext:(id)arg2;
@end


@interface RHArtistMO : NSObject
@property (retain, nonatomic) NSString *name;
@end

@interface RHAlbumMO : NSObject
@end

@interface RHTrackMO : NSObject
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) RHArtistMO *artist;
@property (retain, nonatomic) RHAlbumMO *album;
@end


@protocol RHImageProvider <NSObject>
- (UIImage *)imageForAlbum:(RHAlbumMO *)arg1 size:(struct CGSize)arg2 usePlaceholder:(_Bool)arg3 promise:(id *)arg4;
@end

@interface RHImageCacheController : NSObject <RHImageProvider>
@end


@protocol RHPlayableEntity <NSObject>
@property (readonly, nonatomic) RHTrackMO *playableTrack;
@property (readonly, nonatomic) NSURL *uri;
@end

@interface RHPlayableEntityContext : NSObject
@property (retain, nonatomic) id <RHPlayableEntity> playableEntity;
@end

@interface RHPlayableItem : RHPlayableEntityContext
@end


@interface RHPlayerCachingController : NSObject
+ (id)reuseOrCreateNewPlayableCacheItemsForPlayables:(id)arg1 oldPlaybleCacheItems:(id)arg2;
@property (retain, nonatomic) NSArray *playableCacheItems;
@property (readonly, nonatomic) NSArray *nextPlayables;
@end


@interface AudioPlayerManager : NSObject
@property (retain, nonatomic) RHPlayerCachingController *playerCachingController;
@end


@interface RHPlayerController : NSObject
@property (retain, nonatomic) id <RHImageProvider> imageProvider;
@property (retain, nonatomic) AudioPlayerManager *audioPlayerWrapper;
@property (readonly, nonatomic) RHPlayableItem *afterNextItem;
@property (readonly, nonatomic) RHPlayableItem *nextItem;
- (void)sendNextUpMetadata:(RHTrackMO *)track;
- (void)fetchNextUp;
// - (void)skipNext;
@end

@interface RHAppDelegateRouter : NSObject
@property (retain, nonatomic) RHPlayerController *playerController;
+ (RHAppDelegateRouter *)appDelegate;
@end


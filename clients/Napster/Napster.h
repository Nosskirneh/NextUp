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
- (UIImage *)imageForAlbum:(RHAlbumMO *)album size:(CGSize)size usePlaceholder:(BOOL)placeholder promise:(id *)promise;
@end

@interface RHImageCacheController : NSObject <RHImageProvider>
@end


@protocol RHPlayableEntity <NSObject>
@property (readonly, nonatomic) RHTrackMO *playableTrack;
@end

@interface RHPlayableEntityContext : NSObject
@property (retain, nonatomic) id <RHPlayableEntity> playableEntity;
@end

@interface RHPlayableItem : RHPlayableEntityContext
@end


@interface RHPlayerController : NSObject
@property (retain, nonatomic) id <RHImageProvider> imageProvider;
@property (readonly, nonatomic) RHPlayableItem *afterNextItem;
@property (readonly, nonatomic) RHPlayableItem *nextItem;
- (void)sendNextUpMetadata:(RHTrackMO *)track;
- (void)fetchNextUp;
@end

@interface RHAppDelegateRouter : NSObject
@property (retain, nonatomic) RHPlayerController *playerController;
+ (RHAppDelegateRouter *)appDelegate;
@end


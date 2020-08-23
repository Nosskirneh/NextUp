#import <MediaPlayer/MediaPlayer.h>

@interface MPNowPlayingInfoCenter (Addition)
+ (id)infoCenterForPlayerID:(id)arg1;
@end

@interface MTPlayerItem : NSObject
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
- (void)retrieveArtwork:(id)completion withSize:(CGSize)size;
- (NSString *)contentItemIdentifier;
@end

@interface IMPlayerManifest : NSObject
@property (nonatomic, assign) NSUInteger currentIndex;
- (NSUInteger)count;
- (MTPlayerItem *)objectAtIndex:(NSUInteger)index;
@end

@interface MTUpNextManifest : IMPlayerManifest
@end

@interface MTCompositeManifest : IMPlayerManifest
@property (nonatomic, assign) BOOL isPlayingFromUpNext;
@property (nonatomic, assign) MTUpNextManifest *upNextManifest;
@end

@interface MTPlaybackQueueController : NSObject
@property (nonatomic, retain) MTPlayerItem *lastSentEpisode;

@property (nonatomic, retain) MTCompositeManifest *manifest; // iOS 11.1.2
@property (nonatomic, retain) MTCompositeManifest *compositeManifest; // iOS 11.3.1

+ (id)sharedInstance;

- (BOOL)removeItemWithContentID:(NSString *)itemID;
- (BOOL)nowPlayingInfoCenter:(id)arg removeItemAtOffset:(NSInteger)offset;

- (NSDictionary *)serializeTrack:(MTPlayerItem *)item image:(UIImage *)image skippable:(BOOL)skippable;
- (void)fetchNextUp;
- (void)fetchNextUpFromItem:(MTPlayerItem *)item skippable:(BOOL)skippable;
- (MTCompositeManifest *)getManifest;
- (void)skipNext;
@end

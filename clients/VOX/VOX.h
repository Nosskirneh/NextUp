@interface HNKCache
+ (id)sharedCache;
- (BOOL)fetchImageForFetcher:(id)arg1 formatName:(id)arg2 success:(id)arg3 failure:(id)arg4;
@end

@interface VoxPlayableItem : NSObject
@property (retain, nonatomic) NSString *artist;
@property (retain, nonatomic) NSString *artworkURL;
@property (retain, nonatomic) NSString *name;
@end

@interface VOXPlayerQueue : NSObject
- (VoxPlayableItem *)nextPlayableItem;
- (BOOL)removeItem:(VoxPlayableItem *)item;
- (void)skipNext;
- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(VoxPlayableItem *)item image:(UIImage *)image;
@end

@interface VOXImageFetcher : NSObject
+ (id)fetcherURL:(id)arg1;
@end

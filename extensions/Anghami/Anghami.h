@interface ANGImageDownloadSpec : NSObject
@end

@interface ANGImageDownloader : NSObject
+ (id)sharedInstance;
- (id)getImage:(ANGImageDownloadSpec *)spec callback:(id)callback;
- (id)imageFromCacheForSpec:(ANGImageDownloadSpec *)spec thumbnail:(BOOL *)thumbnail;
@end

@interface ANGSong : NSObject
@property (retain) NSString *artistName;
@property (retain) NSString *coverArtId;
@property (retain) NSString *title;
- (ANGImageDownloadSpec *)imageDownloadSpecWithSize:(long long)size;
@end


@interface ANGPlayQueue : NSObject
@property (readonly, nonatomic) ANGSong *nextSong;
@property (readonly, nonatomic) unsigned long long nextIndex;
@property (nonatomic, retain) ANGSong *lastSentTrack;
- (id)playQueueWithRemovedSong:(ANGSong *)song;

- (void)manuallyUpdate;
- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(ANGSong *)item image:(UIImage *)image;
- (void)skipNext;
@end


@interface PlayQueueSingleton : NSObject
+ (ANGPlayQueue *)currentPlayQueue;
+ (void)removeSongFromQueue:(ANGSong *)song;
@end

@interface Track : NSObject
@property (copy, nonatomic) NSString *albumArtURLString;
@property (copy, nonatomic) NSString *albumArtistString;
@property (copy, nonatomic) NSString *title;
@end

@interface MusicQueueManager : NSObject
@property (nonatomic, retain) Track *lastSentTrack;
@property (readonly, nonatomic) NSArray<Track *> *tracks;
@property (nonatomic) unsigned long long currentTrackIndex;
- (BOOL)hasNext;
- (void)removeTrackAtIndex:(unsigned long long)arg1;

- (void)manuallyUpdate;
- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(Track *)track image:(UIImage *)image skipable:(BOOL)skipable;
- (void)skipNext;
@end

@interface GPMOperationSequence : NSObject
@end

@interface GPMImageFetcher : NSObject
- (id)fetchImageWithURL:(NSURL *)URL size:(CGSize)size quality:(NSUInteger)quality operationSequence:(GPMOperationSequence *)sequence completionHandler:(id)completion;
@end

@interface GPMAppServiceManager : NSObject
@property (readonly) GPMImageFetcher *imageFetcher;
@end

@interface AppDelegate : NSObject
@property (readonly, nonatomic) GPMAppServiceManager *appServiceManager;
@property (readonly, nonatomic) MusicQueueManager *musicQueueManager;
@end

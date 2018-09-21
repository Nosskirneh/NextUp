@interface SPTPlayerTrack : NSObject
@property(readonly, nonatomic, getter=isAdvertisement) BOOL advertisement;
@property(readonly, nonatomic) NSString *subtitle;
@property(readonly, nonatomic) NSString *artistTitle;
@property(readonly, nonatomic) NSURL *coverArtURLSmall;
@property(readonly, nonatomic) NSURL *imageURL;
- (id)trackTitle;
@end


@interface SPTGLUEImageLoader : NSObject
- (id)loadImageForURL:(id)arg1 imageSize:(CGSize)arg2 completion:(id)arg3;
@end

@interface SPTNowPlayingTrackMetadataQueue : NSObject
@property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, retain) NSMutableArray *upcomingMetadatas;
@property (nonatomic, assign) NSInteger processingTracksCount;
- (void)skipToNextTrack;
- (SPTPlayerTrack *)metadataAtRelativeIndex:(long long)arg1;
- (void)deserilizeTrack:(SPTPlayerTrack *)track;
@end


@interface SPTGLUEImageLoaderFactoryImplementation : NSObject
- (id)createImageLoaderForSourceIdentifier:(NSString *)sourceIdentifier;
@end

@interface SPTQueueServiceImplementation : NSObject
@property(retain, nonatomic) SPTGLUEImageLoaderFactoryImplementation *glueImageLoaderFactory;
@end

@interface NowPlayingFeatureImplementation : NSObject
@property(retain, nonatomic) SPTNowPlayingTrackMetadataQueue *trackMetadataQueue;
@property(nonatomic) __weak SPTQueueServiceImplementation *queueService;
@end

@interface SpotifyApplication : UIApplication
@property (nonatomic) __weak NowPlayingFeatureImplementation *remoteControlDelegate;
@end


@interface UIImage (SPT)
+ (id)trackSPTPlaceholderWithSize:(NSInteger)size;
@end

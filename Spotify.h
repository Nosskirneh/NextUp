@interface SPTPlayerTrack : NSObject
@property (readonly, nonatomic, getter=isAdvertisement) BOOL advertisement;
@property (readonly, nonatomic) NSString *subtitle;
@property (readonly, nonatomic) NSString *artistTitle;
@property (readonly, nonatomic) NSURL *coverArtURL;
@property (readonly, nonatomic) NSURL *imageURL;
- (id)trackTitle;
@end

@interface SPTPlayerQueue : NSObject
@property (copy, nonatomic) NSArray<SPTPlayerTrack *> *nextTracks;
@end

@interface SPTPlayerState : NSObject
@property(retain, nonatomic) NSArray *future;
@end

@interface SPTPlayerImpl : NSObject
@property (readonly, copy, nonatomic) SPTPlayerState *state;
- (void)addPlayerObserver:(id)arg1;
@end

@interface SPTQueueTrackImplementation : NSObject
@property (readonly) SPTPlayerTrack *track;
@property (readonly) NSURL *imageURL;
@property (readonly) NSString *subtitle;
@property (readonly) NSString *title;
@property (readonly) NSURL *trackURI;
@end

@interface SPTQueueViewModelDataSource : NSObject
@property (readonly, nonatomic) NSArray<SPTQueueTrackImplementation *> *futureTracks;
@end

@interface SPTGLUEImageLoader : NSObject
- (id)loadImageForURL:(id)arg1 imageSize:(CGSize)arg2 completion:(id)arg3;
@end

@interface SPTQueueViewModelImplementation : NSObject {
    SPTPlayerImpl *_player;
}
@property (nonatomic, retain) SPTPlayerTrack *lastSentTrack;
@property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, strong) SPTQueueViewModelDataSource *dataSource;
- (void)enableUpdates;
- (SPTQueueViewModelDataSource *)removeTracks:(NSSet *)arg1;
- (void)sendNextUpMetadata:(SPTPlayerTrack *)track;
- (void)fetchNextUpForState:(SPTPlayerState *)state;
- (void)skipNext;
@end



@interface SPTStatefulPlayerQueue : NSObject
@property (retain, nonatomic) SPTPlayerState *playerState;
@end

@interface SPTStatefulPlayer : NSObject
@property (retain, nonatomic) SPTStatefulPlayerQueue *queue;
@end

@interface SPTGLUEImageLoaderFactoryImplementation : NSObject
- (id)createImageLoaderForSourceIdentifier:(NSString *)sourceIdentifier;
@end

@interface SPTQueueServiceImplementation : NSObject
@property (retain, nonatomic) SPTGLUEImageLoaderFactoryImplementation *glueImageLoaderFactory;
@end


@interface SPTQueueInteractorImplementation : NSObject
@property (nonatomic) __weak SPTQueueViewModelImplementation *target;
@end

@interface NowPlayingFeatureImplementation : NSObject
@property (nonatomic) __weak SPTQueueServiceImplementation *queueService;
@property (nonatomic) __weak SPTQueueInteractorImplementation *queueInteractor;
@end

@interface SpotifyApplication : UIApplication
@property (nonatomic) __weak NowPlayingFeatureImplementation *remoteControlDelegate;
@end


@interface UIImage (SPT)
+ (id)trackSPTPlaceholderWithSize:(NSInteger)size;
@end



#ifdef __cplusplus
extern "C" {
#endif

    SpotifyApplication *getSpotifyApplication();
    NowPlayingFeatureImplementation *getRemoteDelegate();
    SPTQueueServiceImplementation *getQueueService();
    SPTQueueViewModelImplementation *getQueueImplementation();

#ifdef __cplusplus
}
#endif

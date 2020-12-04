#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SPTService;

@protocol SPTServiceProvider <NSObject>
- (id <SPTService>)provideOptionalServiceForIdentifier:(NSString *)identifier;
- (id <SPTService>)provideServiceForIdentifier:(NSString *)identifier;
@end

@protocol SPTServiceProvider;

@protocol SPTService <NSObject>
@property (atomic, class, readonly) NSString *serviceIdentifier;
- (void)configureWithServices:(id<SPTServiceProvider>)serviceProvider;

@optional
- (void)idleStateWasReached;
- (void)initialViewDidAppear;
- (void)load;
- (void)unload;
@end




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
@property (retain, nonatomic) NSArray *future;
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
@property (readonly, nonatomic) NSArray<SPTQueueTrackImplementation *> *upNextTracks;
@end

@interface SPTQueueViewModelImplementation : NSObject {
    SPTPlayerImpl *_player;
}
@property (nonatomic, strong) SPTQueueViewModelDataSource *dataSource;
- (void)enableUpdates;
- (SPTQueueViewModelDataSource *)removeTracks:(NSSet *)trackSet;
@end


@interface UIImage (SPT)
+ (id)trackSPTPlaceholderWithSize:(NSInteger)size;
@end



@protocol SPTQueueInteractor <NSObject>
@property (nonatomic) __weak SPTQueueViewModelImplementation *target;
@end

@interface SPTNowPlayingServiceImplementation : NSObject<SPTService>
@property (retain, nonatomic) id <SPTQueueInteractor> queueInteractor;
@end

@interface SPTGLUEImageLoader : NSObject
- (id)loadImageForURL:(id)arg1 imageSize:(CGSize)arg2 completion:(id)arg3;
@end

@protocol SPTGLUEImageLoaderFactory <NSObject>
- (SPTGLUEImageLoader *)createImageLoaderForSourceIdentifier:(NSString *)sourceIdentifier;
@end

@protocol SPTGLUEService <SPTService>
- (id <SPTGLUEImageLoaderFactory>)provideImageLoaderFactory;
@end


@protocol SPTPlayer <NSObject>
@end

@protocol SPTPlayerObserver <NSObject>
@optional
- (void)player:(id <SPTPlayer>)player didEncounterError:(NSError *)error;
- (void)player:(id <SPTPlayer>)player stateDidChange:(SPTPlayerState *)newState fromState:(SPTPlayerState *)oldState;
- (void)player:(id <SPTPlayer>)player stateDidChange:(SPTPlayerState *)newState;
@end

@interface SPTPlayerFeatureImplementation : NSObject<SPTService>
- (void)removePlayerObserver:(id<SPTPlayerObserver>)observer;
- (void)addPlayerObserver:(id<SPTPlayerObserver>)observer;
@end

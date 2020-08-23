#import "NUSPTService.h"
#import "Spotify.h"
#import "NUSPTHandler.h"

@interface NUSPTService ()
@property (nonatomic, weak) SPTNowPlayingServiceImplementation *nowPlayingService;
@property (nonatomic, weak) id<SPTGLUEService> glueService;
@property (nonatomic, weak) SPTPlayerFeatureImplementation *playerFeature;
@property (nonatomic, strong) NUSPTHandler *handler;
@end

@implementation NUSPTService

+ (NSString *)serviceIdentifier {
    return @"";
}

- (void)configureWithServices:(id<SPTServiceProvider>)serviceProvider {
    self.nowPlayingService = (SPTNowPlayingServiceImplementation *)[serviceProvider provideServiceForIdentifier:[%c(SPTNowPlayingServiceImplementation) serviceIdentifier]];
    self.glueService = (id<SPTGLUEService>)[serviceProvider provideServiceForIdentifier:[%c(SPTGLUEServiceImplementation) serviceIdentifier]];
    self.playerFeature = (SPTPlayerFeatureImplementation *)[serviceProvider provideServiceForIdentifier:[%c(SPTPlayerFeatureImplementation) serviceIdentifier]];
}

- (SPTGLUEImageLoader *)provideImageLoader {
    return [[self.glueService provideImageLoaderFactory] createImageLoaderForSourceIdentifier:[self.class serviceIdentifier]];
}

- (void)initialViewDidAppear {
    SPTQueueViewModelImplementation *queueViewModel = self.nowPlayingService.queueInteractor.target;
    self.handler.queueViewModel = queueViewModel;

    // This will fill the dataSource's futureTracks, which makes it possible to skip tracks
    if ([queueViewModel respondsToSelector:@selector(enableUpdates)]) {
        [queueViewModel enableUpdates];
    }
}

- (void)load {
    self.handler = [[NUSPTHandler alloc] initWithImageLoader:[self provideImageLoader]];
    [self.playerFeature addPlayerObserver:self.handler];
}

- (void)unload {
    [self.playerFeature removePlayerObserver:self.handler];

    self.nowPlayingService = nil;
    self.glueService = nil;
    self.playerFeature = nil;
    self.handler = nil;
}

@end

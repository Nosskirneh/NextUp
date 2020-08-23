#import "Spotify.h"

@interface NUSPTHandler : NSObject<SPTPlayerObserver>
// Required for skipping
@property (nonatomic, weak) SPTQueueViewModelImplementation *queueViewModel;

- (id)initWithImageLoader:(SPTGLUEImageLoader *)imageLoader;
@end

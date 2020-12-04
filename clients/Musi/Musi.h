#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MTrack : NSObject
@property (nonatomic, assign, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) NSString *creator;
@property (nonatomic, assign, readwrite) NSURL *thumbnailSmallURL;
@end

@interface MMusicTrack : NSObject
@property (nonatomic, assign, readwrite) MTrack *track;
@end


@interface SDImageCache : NSObject
+ (id)sharedImageCache;
- (id)imageFromDiskCacheForKey:(NSString *)key;
@end

@interface SDWebImageManager : NSObject
+ (id)sharedManager;
- (id)downloadImageWithURL:(NSURL *)URL options:(NSUInteger)options progress:(id)progress completed:(id)completion;
@end


@interface MMusicSessionMixTrackProvider : NSObject
@property (nonatomic, assign, readwrite) NSMutableArray *tracks;
- (id)fetchNextTrack;
@end


@interface MMusicSessionPlaylistTrackProvider : NSObject
@property (nonatomic, assign, readwrite) NSMutableArray *shufflePool;
- (MTrack *)fetchNextTrackShuffle;
- (MTrack *)fetchNextTrackLinearWithTrack:(MTrack *)track;
@end


@interface MMusicSessionTrackProviderSource : NSObject
@property (nonatomic, assign, readwrite) MMusicSessionPlaylistTrackProvider *playlistProvider;
@property (nonatomic, assign, readwrite) MMusicSessionMixTrackProvider *mixProvider;
@end

@interface MMusicControllerSettings : NSObject
@property (nonatomic, assign, readwrite) NSInteger mode;
@end

@interface MMusicSession : NSObject
@property (nonatomic, assign, readwrite) BOOL hasNextTrack;
@property (nonatomic, assign, readwrite) MMusicTrack *currentMusicTrack;
@property (nonatomic, assign, readwrite) MMusicSessionTrackProviderSource *currentTrackProviderSource;
@property (nonatomic, assign, readwrite) MMusicControllerSettings *settings;
@property (nonatomic, retain) MTrack *lastSentTrack;
- (MTrack *)peekNextTrack;
- (BOOL)isShuffling;
- (void)fetchNextUp;
- (void)skipNext;
- (NSDictionary *)serializeTrack:(MTrack *)item image:(UIImage *)image;
@end

@interface MNowPlaingViewController : UIViewController
@property (nonatomic, assign, readwrite) MMusicSession *session;
@end


@interface MTabBarController : UIViewController
@property (nonatomic, assign, readwrite) MNowPlaingViewController *nowPlayingViewController;
@end

@interface MSplashViewController : UIViewController
@property (nonatomic, assign, readwrite) MTabBarController *mainViewController;
@end

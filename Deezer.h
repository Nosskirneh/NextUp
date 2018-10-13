#import <MediaPlayer/MPMediaItem.h>

@interface _TtC6Deezer18DeezerIllustration : NSObject
@property (nonatomic, strong) UIImage *image;
// - (NSDictionary *)dictionary;
// + (id)illustrationWithMd5:(NSString *)md5 pictureDomain:(NSString *)domain format:(NSUInteger)format placeholderPrefix:(NSString *)prefix;
@end

@interface _TtC6Deezer19IllustrationManager : NSObject
+ (id)fetchImageFor:(id)illustration size:(CGSize)size effect:(id)effect success:(id)success failure:(id)failure;
@end

@interface DeezerTrack : NSObject
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *artistName;
@property (nonatomic, strong, readwrite) MPMediaItemArtwork *nowPlayingArtwork;
@property (nonatomic, strong, readwrite) NSURL *coverURL50_50;
- (void)fetchNowPlayingArtworkWithCompletion:(id)completion;
- (void)fetchNowPlayingArtwork;
- (NSArray *)illustrations;
@end

@interface DZRMixQueuer : NSObject
@property (nonatomic, assign, readwrite) NSUInteger currentTrackIndex;
@property (nonatomic, strong) NSArray<DeezerTrack *> *tracks;
- (NSDictionary *)serializeTrack:(DeezerTrack *)track image:(UIImage *)image;
- (void)removePlayableAtIndex:(NSUInteger)index;
- (void)fetchNextUp;
- (void)fetchArtworkForFutureNextUp;
- (void)skipNext;
@end

@interface DZRAudioPlayer : NSObject
@property (nonatomic, strong, readwrite) DZRMixQueuer *queuer;
@end

@interface DZRPlayerManager : NSObject
@property (nonatomic, strong, readwrite) DZRAudioPlayer *player;
@end

@interface DZRAppDelegate : NSObject
@property (nonatomic, strong, readwrite) DZRPlayerManager *playerManager;
@end




#ifdef __cplusplus
extern "C" {
#endif

    DZRAppDelegate *getDeezerAppDelegate();
    DZRMixQueuer *getMixQueuer();

#ifdef __cplusplus
}
#endif

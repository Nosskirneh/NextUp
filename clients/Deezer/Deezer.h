#import <MediaPlayer/MPMediaItem.h>

@interface _TtC6Deezer18DeezerIllustration : NSObject
@property (nonatomic, strong) UIImage *image;
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
- (NSArray *)illustrations;
@end


@interface DZRPlaybackQueuer : NSObject
@property(nonatomic) unsigned long long currentTrackIndex;
@property(readonly, nonatomic) NSArray<DeezerTrack *> *tracks;

- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(DeezerTrack *)track image:(UIImage *)image;
- (void)skipNext;
@end

@interface DZRMixQueuer : DZRPlaybackQueuer
- (void)fetchMoreTracksIfNeededAfterSelectTrackAtIndex:(NSUInteger)index;
@end

@interface DZRMyMusicShuffleQueuer : DZRMixQueuer
@end

@interface DZRAudioPlayer : NSObject
@property (nonatomic, strong, readwrite) DZRPlaybackQueuer *queuer;
+ (DZRAudioPlayer *)sharedPlayer;
@end


#ifdef __cplusplus
extern "C" {
#endif
    DZRPlaybackQueuer *getQueuer();
#ifdef __cplusplus
}
#endif

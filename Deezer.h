#import <MediaPlayer/MPMediaItem.h>

@interface DeezerTrack : NSObject
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *artistName;
@property (nonatomic, strong, readwrite) MPMediaItemArtwork *nowPlayingArtwork;
@end

@interface DZRDownloadableObject : NSObject
@property (nonatomic, strong) DeezerTrack *playableObject;
@end

@interface DZRMyMusicShuffleQueuer : NSObject
- (DZRDownloadableObject *)downloadableAtTrackIndex:(NSUInteger)index;
- (NSDictionary *)deserilizeTrack:(DeezerTrack *)track;
@end

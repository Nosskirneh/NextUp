@interface JMediaItem : NSObject
- (UIImage *)getArtworkWithSize:(CGSize)size;
- (NSString *)getArtist;
- (NSString *)getTitle;
@end


@interface JAudioPlayer : NSObject {
    UIImage *mDefArtwork;
}
- (NSArray<JMediaItem *> *)getQueue;
- (void)removeTrack:(int)index;
- (int)getCurTrack;
- (int)getNumTracks;
- (BOOL)removeTrackWithTrack:(int)index;

- (void)fetchNextUp;
- (void)skipNext;
- (NSDictionary *)serializeSong:(JMediaItem *)song;
@end

@interface GIMMe : NSObject
- (id)instanceForType:(id)arg1;
- (id)instanceForKey:(id)arg1;
- (id)instanceFor:(id)arg1;
@end

@interface YTMAppDelegate : NSObject
@property (retain, nonatomic) GIMMe *gimme;
@end


@interface YTImageService : NSObject
@end

@interface YTImageServiceImpl : YTImageService
- (void)makeImageRequestWithURL:(id)arg1 responseBlock:(id)arg2 errorBlock:(id)arg3;
@end


@interface YTIFormattedString : NSObject
- (NSString *)accessibilityLabel;
@end


@interface YTIThumbnailDetails_Thumbnail : NSObject
@property (copy, nonatomic) NSString *URL;
@property (nonatomic) unsigned int height;
@property (nonatomic) unsigned int width;
@end


@interface YTIThumbnailDetails : NSObject
@property (retain, nonatomic) NSMutableArray<YTIThumbnailDetails_Thumbnail *> *thumbnailsArray;
@end


@interface YTIPlaylistPanelVideoRenderer : NSObject
@property (nonatomic) BOOL hasThumbnail;
@property (retain, nonatomic) YTIThumbnailDetails *thumbnail;
@property (nonatomic) BOOL hasTitle;
@property (nonatomic, assign, readwrite) YTIFormattedString *title;
@property (nonatomic) BOOL hasShortBylineText;
@property (nonatomic, assign, readwrite) YTIFormattedString *shortBylineText;
@end

@interface YTMQueueController : NSObject
@property (nonatomic) unsigned long long nowPlayingIndex;
@property (readonly, nonatomic) YTIPlaylistPanelVideoRenderer *nextVideo; // Earlier version
@property (nonatomic, getter=isAutoExtendPlaybackQueueEnabled) BOOL autoExtendPlaybackQueueEnabled;
@property (readonly, nonatomic) unsigned long long queueCount;
- (YTIPlaylistPanelVideoRenderer *)nextVideoWithAutoplay:(BOOL)autoplay;
- (BOOL)hasAutoplayVideo;
- (unsigned long long)nextVideoIndex;
- (void)removeVideoAtIndex:(unsigned long long)arg1;

- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(YTIPlaylistPanelVideoRenderer *)item image:(UIImage *)image;
@end

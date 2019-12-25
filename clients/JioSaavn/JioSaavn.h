@interface SDImageCache : NSObject
+ (id)sharedImageCache;
- (id)imageFromDiskCacheForKey:(NSString *)key;
@end

@interface SDWebImageManager : NSObject
+ (id)sharedManager;
// Old version
- (id)downloadImageWithURL:(NSURL *)URL
                   options:(NSUInteger)options
                  progress:(id)progress
                 completed:(id)completion;
// New version
- (id)loadImageWithURL:(NSURL *)URL
               options:(NSUInteger)options
              progress:(id)progress
             completed:(id)completion;
@end


@interface PlayerVC : UIViewController
@property (retain, nonatomic) UITableView *mainTable;
- (void)removeSong:(NSIndexPath *)indexPath fromTable:(UITableView *)table;
- (NSMutableArray<NSMutableDictionary *> *)getQueue;
- (BOOL)isQueueEmpty;
- (void)getNextSong:(void (^)(NSMutableDictionary *song))completion;
- (long long)CCast_getIndexOnQueueList:(long long)arg1;

- (void)skipNext;
- (void)fetchNextUp;
- (NSDictionary *)serializeSong:(NSDictionary *)song image:(UIImage *)image;
@end

@interface SongUtil : NSObject
+ (NSString *)getPrimaryArtistNamesForSong:(NSDictionary *)song;
@end


@interface AppDelegate : UIResponder
- (PlayerVC *)getPlayerVC;
@end

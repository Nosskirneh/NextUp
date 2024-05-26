#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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

@interface Item : NSObject
@property (nonatomic, assign, readwrite) NSString *title;
@property (nonatomic, assign, readwrite) NSString *artist;
@property (nonatomic, assign, readwrite) NSString *image;
@end


@interface AMNowPlayingViewController
@property (nonatomic, assign, readwrite) NSInteger lookupIndex;
+ (id)sharedInstance;
- (NSArray *)queue;
- (Item *)songAtIndex:(NSInteger)index;
- (void)removeSongAtIndex:(NSInteger)index;

- (void)skipNext;
- (void)fetchNextUp;
- (NSDictionary *)serializeSong:(Item *)song image:(UIImage *)image;
@end

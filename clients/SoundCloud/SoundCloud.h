#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface _TtC8Playback10PlayerItem : NSObject
@property (nonatomic, readonly) NSURL *artworkURL;
@property (nonatomic, readonly) NSString *artistName;
@property (nonatomic, readonly) NSString *title;
@end


@interface _TtC2UI11ImageLoader : NSObject
- (void)loadImageFrom:(id)arg1 successCompletion:(id)arg2 failureCompletion:(id)arg3;
 + (_TtC2UI11ImageLoader *)makeForObjC;
@end

@interface _TtC2UI11ImageLoaderObjFactory : NSObject
 + (_TtC2UI11ImageLoader *)make;
@end

@interface PlaybackService : NSObject
@property (nonatomic, retain) _TtC2UI11ImageLoader *imageLoader;
+ (id)sharedInstance;
- (_TtC2UI11ImageLoader *)getImageLoader;
- (_TtC8Playback10PlayerItem *)nextItemWithInteraction:(unsigned long long)arg1;

- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(_TtC8Playback10PlayerItem *)item image:(UIImage *)image skippable:(BOOL)skippable;
@end

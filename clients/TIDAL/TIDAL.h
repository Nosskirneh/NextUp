#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WMPImageService : NSObject
- (UIImage *)imageForAlbumId:(NSNumber *)albumId
         withImageResourceId:(NSString *)resourceId
                        size:(unsigned long long)size;
- (UIImage *)getDefaultAlbumImageForSize:(unsigned long long)size;
@end

@interface _TtC4WiMP13PlayQueueItem : NSObject
@property (nonatomic, copy) NSString *artistTitle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *imageResourceId;
@property (nonatomic) long long albumId;
@end

@interface _TtC4WiMP16PlayQueueManager : NSObject
@property (nonatomic, retain) WMPImageService *imageService;
@property (nonatomic, retain) _TtC4WiMP13PlayQueueItem *lastSentTrack;
@property (nonatomic, readonly) _TtC4WiMP13PlayQueueItem *nextItem;
@property (nonatomic, readonly) long long currentPosition;
+ (id)sharedInstance;
- (void)removeItemAtIndex:(long long)arg1;

- (void)manuallyUpdate;
- (void)fetchNextUp;
- (NSDictionary *)serializeTrack:(_TtC4WiMP13PlayQueueItem *)track;
- (void)skipNext;
@end

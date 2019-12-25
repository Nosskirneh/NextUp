#import "../Common.h"
#import "notify.h"

#define skipNextID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kSkipNext, bundleIdentifier]
#define manualUpdateID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kManualUpdate, bundleIdentifier]

#define ARTWORK_WIDTH 60
#define ARTWORK_SIZE CGSizeMake(ARTWORK_WIDTH, ARTWORK_WIDTH)

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata);
BOOL initClient(CFNotificationCallback skipNextCallback, CFNotificationCallback manualUpdateCallback);

#ifdef __cplusplus
}
#endif

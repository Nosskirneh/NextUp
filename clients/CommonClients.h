#import "../Common.h"
#import "cfnotify.h"
#import <notify.h>

#define skipNextID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kSkipNext, bundleIdentifier]
#define manualUpdateID(bundleIdentifier) [NSString stringWithFormat:@"%@/%@/%@", NEXTUP_IDENTIFIER, kManualUpdate, bundleIdentifier]

#define CFSkipNextID(bundleIdentifier) [skipNextID(bundleIdentifier) UTF8String]
#define CFManualUpdateID(bundleIdentifier) [manualUpdateID(bundleIdentifier) UTF8String]

#define ARTWORK_WIDTH 60
#define ARTWORK_SIZE CGSizeMake(ARTWORK_WIDTH, ARTWORK_WIDTH)


typedef enum SupportedApplication {
    Anghami,
    AudioMack,
    Deezer,
    GoogleMusic,
    JetAudio,
    JioSaavn,
    Musi,
    Music,
    Napster,
    Podcasts,
    SoundCloud,
    Spotify,
    TIDAL,
    VOX,
    YouTubeMusic
} SupportedApplication;

#ifdef __cplusplus
extern "C" {
#endif

void sendNextTrackMetadata(NSDictionary *metadata);
BOOL shouldInitClient(SupportedApplication app);

void registerCallbacks(CFNotificationCallback skipNextCallback,
                       CFNotificationCallback manualUpdateCallback);
void registerNotify(notify_handler_t skipNextHandler,
                    notify_handler_t manualUpdateHandler);

void registerNotifyTokens(notify_handler_t skipNextHandler,
                          notify_handler_t manualUpdateHandler,
                          int *skipNextToken,
                          int *manualUpdateToken);

BOOL initClient(SupportedApplication app,
                CFNotificationCallback skipNextCallback,
                CFNotificationCallback manualUpdateCallback);
BOOL initClientNotify(SupportedApplication app,
                      notify_handler_t skipNextHandler,
                      notify_handler_t manualUpdateHandler);

#ifdef __cplusplus
}
#endif

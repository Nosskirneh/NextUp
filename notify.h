
#define notificationArguments CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo
#define notify(x) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)x, NULL, NULL, YES)
#define subscribe(x, y) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, x, CFStringRef(y), NULL, 0);

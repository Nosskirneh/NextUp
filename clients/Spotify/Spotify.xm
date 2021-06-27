#import "Spotify.h"
#import "../CommonClients.h"
#import <substrate.h>
#import <HBLog.h>

#define SERVICE_CLASS %c(NUSPTService)


%hook SPTQueueViewModelImplementation

- (void)disableUpdates {
    /* This gets called by the Spotify app itself in some cases.
       I have no idea why, but hooking it seems like a better
       idea compared to always calling `enableUpdates`. */
}

%end

static NSDictionary *_addNextUpServiceToClassScopes(NSDictionary<NSString *, NSArray<NSString *> *> *scopes,
                                                    id classObject) {
    NSMutableDictionary *newScopes = [scopes mutableCopy];
    NSMutableArray *newSessionArray = [newScopes[@"session"] mutableCopy];
    [newSessionArray addObject:classObject];
    newScopes[@"session"] = newSessionArray;
    return newScopes;
}

static NSDictionary *addNextUpServiceToClassNamesScopes(NSDictionary<NSString *, NSArray<NSString *> *> *scopes) {
    return _addNextUpServiceToClassScopes(scopes, NSStringFromClass(SERVICE_CLASS));
}

static NSDictionary *addNextUpServiceToClassScopes(NSDictionary<NSString *, NSArray<NSString *> *> *scopes) {
    return _addNextUpServiceToClassScopes(scopes, SERVICE_CLASS);
}

%group SPTDictionaryBasedServiceList
%hook SPTDictionaryBasedServiceList

- (id)initWithClassNamesByScope:(NSDictionary<NSString *, NSArray<NSString *> *> *)scopes
                   scopeParents:(NSDictionary *)scopeParents {
    return %orig(addNextUpServiceToClassNamesScopes(scopes), scopeParents);
}

%end
%end


%group SPTServiceSystem
%hook SPTServiceList

- (id)initWithScopes:(NSDictionary<NSString *, NSArray<NSString *> *> *)scopes
        scopeParents:(NSDictionary *)scopeParents {
    return %orig(addNextUpServiceToClassNamesScopes(scopes), scopeParents);
}

%end
%end

%group SPTServiceSystem_864
%hook SPTServiceList

- (id)initWithScopeGraph:(id)graph
   serviceClassesByScope:(NSDictionary<NSString *, NSArray<NSString *> *> *)scopes {
    return %orig(graph, addNextUpServiceToClassScopes(scopes));
}

%end
%end


%group AppDelegate
%hook AppDelegate

- (NSArray *)sessionServices {
    NSArray *orig = %orig;
    if (!orig) {
        return @[SERVICE_CLASS];
    }

    NSMutableArray *newArray = [orig mutableCopy];
    [newArray addObject:SERVICE_CLASS];
    return newArray;
}

%end
%end


static inline BOOL initServiceSystem(Class serviceListClass) {
    if (serviceListClass) {
        if ([serviceListClass instancesRespondToSelector:@selector(initWithScopeGraph:serviceClassesByScope:)]) {
            %init(SPTServiceSystem_864);
        } else {
            %init(SPTServiceSystem, SPTServiceList = serviceListClass);
        }
        return YES;
    }
    return NO;
}


void (*orig_UIApplicationMain)(int, char **, NSString *, NSString *);
void hooked_UIApplicationMain(int argc,
                              char *_Nullable *argv,
                              NSString *principalClassName,
                              NSString *delegateClassName) {
    Class Delegate = NSClassFromString(delegateClassName);
    if ([Delegate instancesRespondToSelector:@selector(sessionServices)]) {
        %init(AppDelegate, AppDelegate = Delegate);
    } else {
        Class SpotifyServiceList = objc_getClass("SPTClientServices.SpotifyServiceList");
        if (SpotifyServiceList && [SpotifyServiceList respondsToSelector:@selector(setSessionServices:)]) {
            NSArray *sessionServices = [SpotifyServiceList sessionServices]();
            [SpotifyServiceList setSessionServices:^{
                NSMutableArray *newSessionServicesArray = [sessionServices mutableCopy];
                [newSessionServicesArray addObject:SERVICE_CLASS];
                return newSessionServicesArray;
            }];
        }
    }

    return orig_UIApplicationMain(argc, argv, principalClassName, delegateClassName);
}


%ctor {
    if (shouldInitClient(Spotify)) {
        %init();
        MSHookFunction(((void *)MSFindSymbol(NULL, "_UIApplicationMain")),
                       (void *)hooked_UIApplicationMain, (void **)&orig_UIApplicationMain);

        if (!initServiceSystem(%c(SPTServiceList)) &&
            !initServiceSystem(objc_getClass("SPTServiceSystem.SPTServiceList"))) {
            %init(SPTDictionaryBasedServiceList);
        }
    }
}

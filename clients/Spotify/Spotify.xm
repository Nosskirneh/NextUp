#import "Spotify.h"
#import "../CommonClients.h"
#import <substrate.h>


%hook SPTQueueViewModelImplementation

- (void)disableUpdates {
    /* This gets called by the Spotify app itself in some cases.
       I have no idea why, but hooking it seems like a better
       idea compared to always calling `enableUpdates`. */
}

%end


static NSDictionary *addNextUpServiceToClassNamesScopes(NSDictionary<NSString *, NSArray<NSString *> *> *scopes) {
    NSMutableDictionary *newScopes = [scopes mutableCopy];
    NSMutableArray *newSessionArray = [newScopes[@"session"] mutableCopy];
    [newSessionArray addObject:NSStringFromClass(%c(NUSPTService))];
    newScopes[@"session"] = newSessionArray;
    return newScopes;
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


static inline BOOL initServiceSystem(Class serviceListClass) {
    if (serviceListClass) {
        %init(SPTServiceSystem, SPTServiceList = serviceListClass);
        return YES;
    }
    return NO;
}

%ctor {
    if (shouldInitClient(Spotify)) {
        %init;
        if (!initServiceSystem(%c(SPTServiceList)) &&
            !initServiceSystem(objc_getClass("SPTServiceSystem.SPTServiceList"))) {
            %init(SPTDictionaryBasedServiceList);
        }
    }
}

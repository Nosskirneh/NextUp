#import "Spotify.h"
#import "../CommonClients.h"
#import <substrate.h>
#import <HBLog.h>


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
    return _addNextUpServiceToClassScopes(scopes, NSStringFromClass(%c(NUSPTService)));
}

static NSDictionary *addNextUpServiceToClassScopes(NSDictionary<NSString *, NSArray<NSString *> *> *scopes) {
    return _addNextUpServiceToClassScopes(scopes, %c(NUSPTService));
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


%hook AppDelegate

- (NSArray *)sessionServices {
    NSArray *orig = %orig;
    if (!orig) {
        return @[%c(NUSPTService)];
    }

    NSMutableArray *newArray = [orig mutableCopy];
    [newArray addObject:%c(NUSPTService)];
    return newArray;
}

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


%ctor {
    if (shouldInitClient(Spotify)) {
        Class AppDelegateClass = objc_getClass("AppKernelFeature.AppDelegate");
        if ([AppDelegateClass instancesRespondToSelector:@selector(sessionServices)]) {
            %init(AppDelegate = AppDelegateClass);
        } else if (!initServiceSystem(%c(SPTServiceList)) &&
                   !initServiceSystem(objc_getClass("SPTServiceSystem.SPTServiceList"))) {
            %init(SPTDictionaryBasedServiceList);
        }
    }
}

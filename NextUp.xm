#import "NUMetadataSaver.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Common.h"
#import "Spotify.h"
#import "Deezer.h"
#import "Music.h"
#import "Headers.h"
#import "DRMOptions.mm"

#define ARTWORK_SIZE CGSizeMake(60, 60)


NUMetadataSaver *metadataSaver;

/* Fetch Apple Music metadata */
%group Music

    void APMSkipNext(notificationArguments) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAPMSkipNext object:nil];
    }

    void APMManualUpdate(notificationArguments) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAPMManualUpdate object:nil];
    }

    %hook MPCMediaPlayerLegacyPlaylistManager

    - (id)init {
        MPCMediaPlayerLegacyPlaylistManager *orig = %orig;
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(skipNext)
                                                     name:kAPMSkipNext
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(fetchNextUp)
                                                     name:kAPMManualUpdate
                                                   object:nil];
        return orig;
    }

    - (void)player:(id)player currentItemDidChangeFromItem:(MPMediaItem *)from toItem:(MPMediaItem *)to {
        %orig;
        [self fetchNextUp];
    }

    - (void)queueFeederDidInvalidateRealShuffleType:(id)queueFeeder {
        %orig;
        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        NUMediaItem *next = [self metadataItemForPlaylistIndex:[self currentIndex] + 1];

        if (!next)
            next = [self metadataItemForPlaylistIndex:0];

        if (next)
            [self fetchNextUpItem:next withArtworkCatalog:[next artworkCatalogBlock]];
    }

    %new
    - (void)skipNext {
        int nextIndex = [self currentIndex] + 1;
        if (![self metadataItemForPlaylistIndex:nextIndex]) {
            nextIndex = 0;

            if ([self currentIndex] == nextIndex)
                return [self fetchNextUp]; // This means we have no tracks left in the queue
        }

        [self removeItemAtPlaybackIndex:nextIndex];

        NUMediaItem *next = [self metadataItemForPlaylistIndex:nextIndex];
        if (next) 
            [self fetchNextUpItem:next withArtworkCatalog:[next artworkCatalogBlock]];
    }

    %new
    - (NSDictionary *)serializeTrack:(NUMediaItem *)item image:(UIImage *)image {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        UIImage *artwork = image;

        if ([item isKindOfClass:%c(MPCModelGenericAVItem)])
            metadata[@"trackTitle"] = [item mainTitle];
        else if ([item isKindOfClass:%c(MPMediaItem)]) {
            metadata[@"trackTitle"] = item.title;

            if (!image)
                artwork = [item.artwork imageWithSize:ARTWORK_SIZE];
        }

        metadata[@"artistTitle"] = item.artist;

        metadata[@"artwork"] = UIImagePNGRepresentation(artwork);
        return metadata;
    }

    %new
    - (void)fetchNextUpItem:(MPMediaItem *)item withArtworkCatalog:(block)artworkBlock {
        MPArtworkCatalog *catalog = artworkBlock();

        [catalog setFittingSize:ARTWORK_SIZE];
        catalog.destinationScale = [UIScreen mainScreen].scale;

        [catalog requestImageWithCompletionHandler:^(UIImage *image) {
            NSDictionary *metadata = [self serializeTrack:item image:image];
            sendNextTrackMetadata(metadata, NUMusicApplication);
        }];
    }

    %end
%end
// ---



/* Spotify */
%group Spotify

    void SPTSkipNext(notificationArguments) {
        [getQueueImplementation() skipNext];
    }

    void SPTManualUpdate(notificationArguments) {
        SPTQueueViewModelImplementation *queueViewModel = getQueueImplementation();
        if (!queueViewModel)
            return;
        SPTPlayerImpl *player = MSHookIvar<SPTPlayerImpl *>(queueViewModel, "_player");
        [queueViewModel fetchNextUpForState:player.state];
    }

    SpotifyApplication *getSpotifyApplication() {
        return (SpotifyApplication *)[UIApplication sharedApplication];
    }

    NowPlayingFeatureImplementation *getRemoteDelegate() {
        return getSpotifyApplication().remoteControlDelegate;
    }

    SPTQueueServiceImplementation *getQueueService() {
        return getRemoteDelegate().queueService;
    }

    SPTQueueViewModelImplementation *getQueueImplementation() {
        return getRemoteDelegate().queueInteractor.target;
    }

    // Fetch next track on app launch
    %hook SPBarViewController

    - (void)viewDidLoad {
        %orig;

        // Load image loader
        SPTQueueViewModelImplementation *queueViewModel = getQueueImplementation();
        queueViewModel.imageLoader = [getQueueService().glueImageLoaderFactory createImageLoaderForSourceIdentifier:@"se.nosskirneh.nextup"];

        // Add observer (otherwise this is only done as late as when opening the now playing view)
        SPTPlayerImpl *player = MSHookIvar<SPTPlayerImpl *>(queueViewModel, "_player");
        [player addPlayerObserver:queueViewModel];

        // This will fill the dataSource's futureTracks, which makes it possible to skip tracks
        [queueViewModel enableUpdates];
    }

    %end


    %hook SPTQueueViewModelImplementation

    %property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;

    - (void)player:(SPTPlayerImpl *)player stateDidChange:(SPTPlayerState *)newState fromState:(SPTPlayerState *)oldState {
        %orig;

        [self fetchNextUpForState:newState];
    }

    %new
    - (void)fetchNextUpForState:(SPTPlayerState *)state {
        NSArray *next = state.future;
        if (next.count > 0)
            [self sendNextUpMetadata:next[0]];
    }

    %new
    - (void)skipNext {
        if (!self.dataSource.futureTracks)
            return;

        SPTQueueTrackImplementation *track = self.dataSource.futureTracks[0];
        NSSet *tracks = [NSSet setWithArray:@[track]];
        [self removeTracks:tracks];
    }

    %new
    - (void)sendNextUpMetadata:(SPTPlayerTrack *)track {
        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[@"trackTitle"] = [track trackTitle];
        metadata[@"artistTitle"] = track.artistTitle;

        // Artwork
        CGSize imageSize = ARTWORK_SIZE;
        __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

        // Do this lastly
        if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
            [self.imageLoader loadImageForURL:track.coverArtURL imageSize:imageSize completion:^(UIImage *img) {
                if (img)
                    image = img;

                metadata[@"artwork"] = UIImagePNGRepresentation(image);
                sendNextTrackMetadata(metadata, NUSpotifyApplication);
            }];
        }
    }

    %end

%end
// ---



/* Deezer */
%group Deezer
    void DZRSkipNext(notificationArguments) {
        [getMixQueuer() skipNext];
    }

    void DZRManualUpdate(notificationArguments) {
        [getMixQueuer() fetchNextUp];
    }

    DZRAppDelegate *getDeezerAppDelegate() {
        return (DZRAppDelegate *)[[UIApplication sharedApplication] delegate];
    }

    DZRMixQueuer *getMixQueuer() {
        return getDeezerAppDelegate().playerManager.player.queuer;
    }

    %hook DZRMixQueuer

    - (void)setCurrentTrackIndex:(NSUInteger)index {
        %orig;

        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        if (self.tracks.count <= self.currentTrackIndex + 1)
            return;

        DeezerTrack *track = self.tracks[self.currentTrackIndex + 1];
        [track fetchNowPlayingArtworkWithCompletion:^(id image) {
            NSDictionary *metadata = [self serializeTrack:track image:image];
            sendNextTrackMetadata(metadata, NUDeezerApplication);
        }];
    }

    %new
    - (void)skipNext {
        NSMutableArray *newTracks = [self.tracks mutableCopy];
        [newTracks removeObjectAtIndex:self.currentTrackIndex + 1];
        self.tracks = newTracks;

        [self fetchNextUp];
    }

    %new
    - (NSDictionary *)serializeTrack:(DeezerTrack *)track image:(UIImage *)image {
        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[@"trackTitle"] = track.title;
        metadata[@"artistTitle"] = track.artistName;
        UIImage *artwork = image;
        // `nowPlayingArtwork` has to be fetched. It doesn't exist a method to do that
        // with a completionhandler, so I've implemented this in DeezerTrack below
        if (!artwork)
            artwork = [track.nowPlayingArtwork imageWithSize:ARTWORK_SIZE];
        metadata[@"artwork"] = UIImagePNGRepresentation(artwork);
        return metadata;
    }

    %end


    %hook DeezerTrack

    %new
    - (void)fetchNowPlayingArtworkWithCompletion:(void (^)(UIImage *))completion {
        NSArray *illustrations = [self illustrations];
        _TtC6Deezer18DeezerIllustration *illustration = [illustrations firstObject];

        [%c(_TtC6Deezer19IllustrationManager) fetchImageFor:illustration
                                                       size:ARTWORK_SIZE
                                                     effect:nil
                                                    success:^(_TtC6Deezer18DeezerIllustration *illustration, UIImage *image) {
                                                        completion(image);
                                                  } failure:nil];
    }

    %end

%end
// ---

/* Adding the widget */
%group SpringBoard

    void setMediaAppAndSendShowNextUp(NUMediaApplication app) {
        metadataSaver.mediaApplication = app;
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
    }

    %hook SBMediaController

    - (void)_setNowPlayingApplication:(SBApplication *)app {
        if ([app.bundleIdentifier isEqualToString:kSpotifyBundleID]) {
            notify(kSPTManualUpdate);
            setMediaAppAndSendShowNextUp(NUSpotifyApplication);
        } else if ([app.bundleIdentifier isEqualToString:kMusicBundleID]) {
            notify(kAPMManualUpdate);
            setMediaAppAndSendShowNextUp(NUMusicApplication);
        } else if ([app.bundleIdentifier isEqualToString:kDeezerBundleID]) {
            notify(kDZRManualUpdate);
            setMediaAppAndSendShowNextUp(NUDeezerApplication);
        } else {
            metadataSaver.mediaApplication = NUUnsupportedApplication;
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
        }
        
        %orig;
    }

    %end

    %hook SBDashBoardNotificationAdjunctListViewController

    - (id)init {
        id orig = %orig;
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(showNextUp)
                                                     name:kShowNextUp
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(hideNextUp)
                                                     name:kHideNextUp
                                                   object:nil];
        return orig;
    }

    %new
    - (SBDashBoardMediaControlsViewController *)mediaControlsController {
        SBDashBoardNowPlayingController *nowPlayingController = [self valueForKey:@"_nowPlayingController"];
        return nowPlayingController.controlsViewController;
    }

    %new
    - (void)showNextUp {
        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        // Mark NextUp as should be visible
        mediaControlsController.shouldShowNextUp = YES;

        if (mediaControlsController.showingNextUp)
            return;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:NO];
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 2;
        [self _updateMediaControlsVisibilityAnimated:YES];

        // Not restoring width and height here since we want
        // to do it when the animation is complete
    }

    %new
    - (void)hideNextUp {
        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        // Mark NextUp as should be visible
        mediaControlsController.shouldShowNextUp = NO;

        if (!mediaControlsController.showingNextUp)
            return;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:YES];
    }

    // Restore width and height (touches don't work otherwise)
    %new
    - (void)nextUpViewWasAdded {
        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        CGRect frame = mediaControlsController.view.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.frame.size.height;
        mediaControlsController.view.frame = frame;
    }

    %end


    %hook SBDashBoardMediaControlsViewController
    %property (nonatomic, retain) NextUpViewController *nextUpViewController;
    %property (nonatomic, assign) BOOL nextUpNeedPostFix;
    %property (nonatomic, assign) BOOL shouldShowNextUp;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;

    - (void)viewDidLoad {
        %orig;

        [self initNextUp];
    }

    - (CGSize)preferredContentSize {
        CGSize orig = %orig;
        if (self.shouldShowNextUp)
            orig.height += 105;
        return orig;
    }

    - (void)_layoutMediaControls {
        %orig;

        if (self.shouldShowNextUp)
            [self addNextUpView];
    }

    %new
    - (void)initNextUp {
        if(![self isNextUpInitialized]) {
            self.nextUpViewController = [[%c(NextUpViewController) alloc] init];
            self.nextUpViewController.cornerRadius = 15;
            self.nextUpViewController.metadataSaver = metadataSaver;

            self.nextUpInitialized = YES;
        }
    }

    - (void)handleEvent:(SBDashBoardEvent *)event {
        %orig;

        if (event.type == 18 && self.nextUpNeedPostFix) { // SignificantUserInteraction
            self.nextUpNeedPostFix = NO;
            [self.nextUpViewController viewDidAppear:YES];
            [[self _presenter] nextUpViewWasAdded];
        }
    }

    %new
    - (void)addNextUpView {
        [self.view addSubview:self.nextUpViewController.view];

        UIView *mediaView = ((UIViewController *)[self valueForKey:@"_mediaControlsPanelViewController"]).view;

        self.nextUpViewController.view.frame = CGRectMake(mediaView.frame.origin.x,
                                                          mediaView.frame.origin.y + mediaView.frame.size.height,
                                                          mediaView.frame.size.width,
                                                          105);
        self.showingNextUp = YES;
        self.nextUpNeedPostFix = YES;
    }

    %new
    - (void)removeNextUpView {
        [self.nextUpViewController.view removeFromSuperview];
        self.showingNextUp = NO;
    }

    %end
%end
// ---

/* ColorFlow 4 support */
%group ColorFlow
    %hook SBDashBoardMediaControlsViewController
    - (void)cfw_colorize:(CFWColorInfo *)colorInfo {
        %orig;

        self.nextUpViewController.headerLabel.textColor = colorInfo.primaryColor;
        [self.nextUpViewController.mediaView cfw_colorize:colorInfo];
    }

    - (void)cfw_revert {
        %orig;

        self.nextUpViewController.headerLabel.textColor = UIColor.whiteColor;
        [self.nextUpViewController.mediaView cfw_revert];
    }
    %end
%end
// ---


%group Welcome
%hook SBLockScreenManager

- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
    OBFS_UIALERT(packageShown$bs(), WelcomeMsg$bs(), OK$bs());

    return %orig;
}

%end
%end


%ctor {
    // License check – if no license found, present message. If no valid license found, do not init
    switch (check_lic(licensePath$bs(), package$bs())) {
        case CheckNoLicense:
            if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpringBoardBundleID])
                %init(Welcome);
            break;
        case CheckInvalidLicense:
            break;
        case CheckValidLicense:
            goto init;
            break;
        case CheckUDIDsDoNotMatch:
            break;
    }
    return;
    // ---

    init:

    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpringBoardBundleID]) {
        %init(SpringBoard);
        %init(ColorFlow);
        metadataSaver = [[NUMetadataSaver alloc] init];
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpotifyBundleID]) {
         if (preferences[kEnableSpotify] && ![preferences[kEnableSpotify] boolValue])
            return;

        %init(Spotify);
        subscribe(&SPTSkipNext, kSPTSkipNext);
        subscribe(&SPTManualUpdate, kSPTManualUpdate);
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kMusicBundleID]) {
         if (preferences[kEnableMusic] && ![preferences[kEnableMusic] boolValue])
            return;

        %init(Music);
        subscribe(&APMSkipNext, kAPMSkipNext);
        subscribe(&APMManualUpdate, kAPMManualUpdate);
    } else {
         if (preferences[kEnableDeezer] && ![preferences[kEnableDeezer] boolValue])
            return;

        %init(Deezer);
        subscribe(&DZRSkipNext, kDZRSkipNext);
        subscribe(&DZRManualUpdate, kDZRManualUpdate);
    }
}

#import "NUMetadataSaver.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Common.h"
#import "Spotify.h"
#import "Deezer.h"
#import "Music.h"
#import "Headers.h"

NUMetadataSaver *metadataSaver;

/* Fetch Apple Music metadata */
%group Music

    %hook SBMediaController

    - (void)setNowPlayingInfo:(id)arg {
        %log;
        %orig;

        if (![self.nowPlayingApplication.mainSceneID isEqualToString:kMusicBundleID])
            return;

        MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];

        // Do not compute if the current track is the same as last time
        static long long prevTrackID = 0;
        long long currTrackID = player.nowPlayingItem.persistentID;
        if (currTrackID == prevTrackID && prevTrackID != 0)
            return;
        prevTrackID = currTrackID;

        id item = [player nowPlayingItemAtIndex:player.indexOfNowPlayingItem + 1];

        NSDictionary *metadata;
        if (!item) // No more tracks upcoming, use the first one
            item = [player nowPlayingItemAtIndex:0];

        if ([item isKindOfClass:%c(MPModelObjectMediaItem)])
            return [self handleNextUpModelObjectMediaItem:item];
        else
            metadata = [player serializeTrack:item image:nil];

        sendNextTrackMetadata(metadata);
    }

    %new
    - (void)handleNextUpModelObjectMediaItem:(MPMediaItem *)item {
        MPModelObjectMediaItem *object = (MPModelObjectMediaItem *)item;
        MPModelSong *song = object.modelObject;
        block artworkBlock = [song valueForModelKey:@"MPModelPropertySongArtwork"];

        MPArtworkCatalog *catalog = artworkBlock();
        [catalog setFittingSize:CGSizeMake(60, 60)];
        catalog.destinationScale = 2.0;

        [catalog requestImageWithCompletionHandler:^(UIImage *image) {
            MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];
            NSDictionary *metadata = [player serializeTrack:item image:image];
            sendNextTrackMetadata(metadata);
        }];
    }

    %end

    %hook MPMusicPlayerController

    %new
    - (NSDictionary *)serializeTrack:(id)item image:(UIImage *)image {
        NSMutableDictionary *metadata = [NSMutableDictionary new];
        MPMediaItem *track = (MPMediaItem *)item;
        metadata[@"trackTitle"] = track.title;
        metadata[@"artistTitle"] = track.artist;

        UIImage *artwork = image;
        if (!image)
            artwork = [track.artwork imageWithSize:CGSizeMake(60, 60)];

        metadata[@"artwork"] = UIImagePNGRepresentation(artwork);
        return metadata;
    }

    %end
%end
// ---



/* Spotify */
%group Spotify

    void SPTSkipNext(notificationArguments) {
        [getQueueImplementation() skipNext];
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


    %hook SPTQueueViewModelImplementation

    %property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;

    - (void)player:(id)player queueDidChange:(SPTPlayerQueue *)queue {
        %orig;

        if (!self.imageLoader)
            self.imageLoader = [getQueueService().glueImageLoaderFactory createImageLoaderForSourceIdentifier:@"se.nosskirneh.nextup"];

        if (queue.nextTracks.count > 0) {
            SPTPlayerTrack *track = queue.nextTracks[0];
            [self sendNextUpMetadata:track];
        }
    }

    %new
    - (void)skipNext {
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
        CGSize imageSize = CGSizeMake(60, 60);
        __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

        // Do this lastly
        if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
            [self.imageLoader loadImageForURL:track.coverArtURLSmall imageSize:imageSize completion:^(UIImage *img) {
                if (img)
                    image = img;

                metadata[@"artwork"] = UIImagePNGRepresentation(image);
                sendNextTrackMetadata(metadata);
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
            sendNextTrackMetadata(metadata);
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
            artwork = [track.nowPlayingArtwork imageWithSize:CGSizeMake(60, 60)];
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
                                                       size:CGSizeMake(60, 60)
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

    %hook SBMediaController

    - (void)_setNowPlayingApplication:(SBApplication *)app {
        %log;
        %orig;

        if (!app ||
            (![app.bundleIdentifier isEqualToString:kSpotifyBundleID] &&
             ![app.bundleIdentifier isEqualToString:kDeezerBundleID] &&
             ![app.bundleIdentifier isEqualToString:kMusicBundleID])) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kClearMetadata object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
    }

    %end

    %hook SBDashBoardNotificationAdjunctListViewController

    - (id)init {
        %log;

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
        %log;

        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        if (mediaControlsController.showingNextUp)
            return;

        // Mark NextUp as should be visible
        mediaControlsController.shouldShowNextUp = YES;

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
        %log;

        SBDashBoardMediaControlsViewController *mediaControlsController = [self mediaControlsController];

        if (!mediaControlsController.showingNextUp)
            return;

        // Mark NextUp as should be visible
        mediaControlsController.shouldShowNextUp = NO;

        // Reload the widget
        MSHookIvar<NSInteger>(self, "_nowPlayingState") = 0;
        [self _updateMediaControlsVisibilityAnimated:YES];
    }

    // Restore width and height (touches don't work otherwise)
    %new
    - (void)nextUpViewWasAdded {
        %log;
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

        self.shouldShowNextUp = YES;

        if (self.shouldShowNextUp)
            [self addNextUpView];
    }

    %new
    - (void)initNextUp {
        if(![self isNextUpInitialized]) {
            self.nextUpViewController = [[%c(NextUpViewController) alloc] init];
            self.nextUpViewController.cornerRadius = 15;
            self.nextUpViewController.metadataSaver = metadataSaver;

            // self.hapticGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

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



%ctor {
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpringBoardBundleID]) {
        %init(SpringBoard);
        %init(Music);
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpotifyBundleID]) {
        %init(Spotify)
        subscribe(&SPTSkipNext, kSPTSkipNext);
    } else {
        %init(Deezer)
        subscribe(&DZRSkipNext, kDZRSkipNext);
    }

    metadataSaver = [[NUMetadataSaver alloc] init];
}

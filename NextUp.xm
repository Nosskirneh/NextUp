#import "NUMetadataSaver.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Common.h"
#import "Spotify.h"
#import "Deezer.h"
#import "Headers.h"


NUMetadataSaver *metadataSaver;

/* Fetch Apple Music metadata */
%group Music

    @interface MPMusicPlayerController (Addition)
    - (NSDictionary *)deserilizeTrack:(MPMediaItem *)track;
    - (id)nowPlayingItemAtIndex:(NSUInteger)arg1;
    @end


    %hook SBMediaController

    - (void)setNowPlayingInfo:(id)arg {
        %orig;

        if (![self.nowPlayingApplication.mainSceneID isEqualToString:kMusicBundleID])
            return;

        MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];

        // Do not compute if the current track is the same as last time
        static long long prevTrackID = 0;
        long long currTrackID = player.nowPlayingItem.persistentID;
        if (currTrackID == prevTrackID)
            return;
        prevTrackID = currTrackID;

        MPMediaItem *item = [player nowPlayingItemAtIndex:player.indexOfNowPlayingItem + 1];

        NSDictionary *metadata;
        if (!item) // No more tracks upcoming, use the first one
            metadata = [player deserilizeTrack:[player nowPlayingItemAtIndex:0]];
        else
            metadata = [player deserilizeTrack:item];

        sendNextTrackMetadata(metadata);


        // For debugging
        static int x = 0;
        if (x > 2) {
            HBLogDebug(@"posting notif for x: %d", x);
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
            x = 0;
        }
        x++;
    }

    %end

    %hook MPMusicPlayerController

    %new
    - (NSDictionary *)deserilizeTrack:(MPMediaItem *)track {
        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[@"trackTitle"] = track.title;
        metadata[@"artistTitle"] = track.artist;
        UIImage *artwork = [track.artwork imageWithSize:CGSizeMake(46, 46)];
        metadata[@"artwork"] = UIImagePNGRepresentation(artwork);
        return metadata;
    }

    %end
%end
// ---



/* Spotify */
%group Spotify

    void skipNext(notificationArguments) {
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

    %new
    - (void)skipNext {
        SPTPlayerTrack *track = self.dataSource.futureTracks[0];
        NSSet *tracks = [NSSet setWithArray:@[track]];
        [self removeTracks:tracks];
    }

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
    - (void)sendNextUpMetadata:(SPTPlayerTrack *)track {
        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[@"trackTitle"] = [track trackTitle];
        metadata[@"artistTitle"] = track.artistTitle;

        // Artwork
        CGSize imageSize = CGSizeMake(46, 46);
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
    %hook DZRMyMusicShuffleQueuer

    - (void)setDownloadablesByPlayableUniqueIDs:(NSMutableArray *)array {
        %orig;

        DZRDownloadableObject *downloadObject = [self downloadableAtTrackIndex:1];
        NSDictionary *metadata = [self deserilizeTrack:downloadObject.playableObject];

        sendNextTrackMetadata(metadata);
    }

    %new
    - (NSDictionary *)deserilizeTrack:(DeezerTrack *)track {
        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[@"trackTitle"] = track.title;
        metadata[@"artistTitle"] = track.artistName;
        UIImage *artwork = [track.nowPlayingArtwork imageWithSize:CGSizeMake(46, 46)];
        metadata[@"artwork"] = UIImagePNGRepresentation(artwork);
        return metadata;
    }


    %end
%end
// ---

/* Adding the widget */
%group SpringBoard

    %hook SBDashBoardNotificationAdjunctListViewController

    - (id)init {
        %log;

        id orig = %orig;
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(showNextUp)
                                                     name:kShowNextUp
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
        subscribe(&skipNext, kSPTSkipNext);
    } else {
        %init(Deezer)
    }

    metadataSaver = [[NUMetadataSaver alloc] init];
}

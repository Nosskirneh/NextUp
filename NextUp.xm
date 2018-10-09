#import <SpringBoard/SBMediaController.h>
#import "NUMetadataSaver.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Common.h"
#import "Spotify.h"
#import "Deezer.h"
#import "Headers.h"


#define isAppCurrentMediaApp(x) [((SBMediaController *)[%c(SBMediaController) sharedInstance]).nowPlayingApplication.mainSceneID isEqualToString:x]


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

        if (![self.nowPlayingApplication.mainSceneID isEqualToString:kMusicBundleIdentifier])
            return;

        MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];

        // Do not compute if the current track is the same as last time
        static long long prevTrackID = 0;
        long long currTrackID = player.nowPlayingItem.persistentID;
        if (currTrackID == prevTrackID)
            return;
        prevTrackID = currTrackID;

        NSMutableArray *upcomingMetadatas = [NSMutableArray new];
        int i = player.indexOfNowPlayingItem + 1;
        MPMediaItem *item = [player nowPlayingItemAtIndex:i];
        while (item && upcomingMetadatas.count < 3) {
            NSDictionary *metadata = [player deserilizeTrack:item];
            [upcomingMetadatas addObject:metadata];

            i++;
            item = [player nowPlayingItemAtIndex:i];
        };

        if (upcomingMetadatas.count == 0) { // No more tracks, use the first one
            NSDictionary *metadata = [player deserilizeTrack:[player nowPlayingItemAtIndex:0]];
            [upcomingMetadatas addObject:metadata];
        }

        sendNextTracks(upcomingMetadatas);


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

    SpotifyApplication *getSpotifyApplication() {
        return (SpotifyApplication *)[UIApplication sharedApplication];
    }

    NowPlayingFeatureImplementation *getRemoteDelegate() {
        return getSpotifyApplication().remoteControlDelegate;
    }

    SPTNowPlayingTrackMetadataQueue *getTrackMetadataQueue() {
        return getRemoteDelegate().trackMetadataQueue;
    }

    SPTQueueServiceImplementation *getQueueService() {
        return getRemoteDelegate().queueService;
    }


    %hook SPTNowPlayingTrackMetadataQueue

    %property (nonatomic, retain) SPTGLUEImageLoader *imageLoader;
    %property (nonatomic, retain) NSMutableArray *upcomingMetadatas;
    %property (nonatomic, assign) NSInteger processingTracksCount;

    - (void)player:(id)player didMoveToRelativeTrack:(id)arg {
        %orig;

        if (!self.imageLoader)
            self.imageLoader = [getQueueService().glueImageLoaderFactory createImageLoaderForSourceIdentifier:@"se.nosskirneh.nextup"];

        self.upcomingMetadatas = [NSMutableArray new];
        int i = 1;
        SPTPlayerTrack *track = [self metadataAtRelativeIndex:i];
        while (track && self.upcomingMetadatas.count < 3) {
            HBLogDebug(@"track: %@", track);
            [self deserilizeTrack:track];
            i++;
            track = [self metadataAtRelativeIndex:i];
        };
        // sendNextTracks(self.upcomingMetadatas);
    }

    %new
    - (void)deserilizeTrack:(SPTPlayerTrack *)track {
        self.processingTracksCount++;

        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[@"trackTitle"] = [track trackTitle];
        metadata[@"artistTitle"] = track.artistTitle;

        // Artwork
        CGSize imageSize = CGSizeMake(46, 46);
        __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

        // Do this lastly
        if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
            [self.imageLoader loadImageForURL:track.coverArtURLSmall imageSize:imageSize completion:^(UIImage *img) {
                self.processingTracksCount--;
                if (img)
                    image = img;

                metadata[@"artwork"] = UIImagePNGRepresentation(image);
                [self.upcomingMetadatas addObject:metadata];

                if (self.processingTracksCount == 0) {
                    // Send message to springboard
                    HBLogDebug(@"last artwork");
                    sendNextTracks(self.upcomingMetadatas);
                }
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

        NSMutableArray *upcomingMetadatas = [NSMutableArray new];
        int i = 1;
        DZRDownloadableObject *downloadObject = [self downloadableAtTrackIndex:i];
        while (downloadObject && upcomingMetadatas.count < 3) {
            NSDictionary *metadata = [self deserilizeTrack:downloadObject.playableObject];
            [upcomingMetadatas addObject:metadata];

            i++;
            downloadObject = [self downloadableAtTrackIndex:i];
        };

        sendNextTracks(upcomingMetadatas);
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
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoard);
        %init(Music);
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpotifyBundleIdentifier]) {
        %init(Spotify)
    } else {
        %init(Deezer)
    }

    metadataSaver = [[NUMetadataSaver alloc] init];
}

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

        NSMutableArray *upcomingMetadatas = [NSMutableArray new];
        int i = 1;
        MPMediaItem *item = [player nowPlayingItemAtIndex:i];
        while (item) {
            NSDictionary *metadata = [player deserilizeTrack:item];
            [upcomingMetadatas addObject:metadata];

            i++;
            item = [player nowPlayingItemAtIndex:i];
        };

        sendNextTracks(upcomingMetadatas);
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
        while (track) {
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
        while (downloadObject) {
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

    // %hook NCNotificationCombinedListViewController

    // -(double)_settlingYPositionForRevealForScrollView:(id)arg1  {
    //     %log;
    //     double org = %orig;
    //     HBLogDebug(@"_settlingYPositionForRevealForScrollView: %f", org);
    //     return org;
    // }

    // -(double)_revealHintViewPosition {
    //     %log;
    //     double org = %orig;
    //     HBLogDebug(@"_revealHintViewPosition: %f", org);
    //     return org;
    // }

    // %end

    %subclass NextUpDashBoardAdjunctItemView : SBDashBoardAdjunctItemView

    - (void)layoutSubviews {
        %orig;
        if (!self.contentHost) return;
        self.contentHost.containerSize = self.bounds.size;
    }

    %end


    %hook SBDashBoardNotificationAdjunctListViewController
    %property (nonatomic, retain) SBDashBoardAdjunctItemView *nextUpContainerView;
    %property (nonatomic, retain) NextUpViewController *nextUpViewController;
    // %property (nonatomic, retain) UIImpactFeedbackGenerator *nextUpHapticGenerator;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;

    - (id)init {
        %log;
        id orig = %orig;
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(tryToShowNextUp)
                                                     name:kShowNextUp
                                                   object:nil];
        return orig;
    }

    - (void)_updateMediaControlsVisibility {
        %log;
        %orig;

        if (self.showingNextUp) // Put it at the end
            [self insertNextUpSubviewAtEnd];
    }

    - (void)_updateAdjunctListItems {
        %log;
        %orig;
    }

    - (void)viewDidLoad {
        if(![self isShowingNextUp]) {
            %log;
            %orig;

            [self initNextUpContainerView];
        }
    }

    %new
    - (void)tryToShowNextUp {
        %log;
        if ([self isShowingMediaControls])
            [self showNextUp];
    }

    %new
    - (void)initNextUpContainerView {
        %log;
        if(![self isNextUpInitialized]) {
            self.nextUpViewController = [[%c(NextUpViewController) alloc] init];
            self.nextUpViewController.cornerRadius = 15;
            self.nextUpViewController.metadataSaver = metadataSaver;

            self.nextUpContainerView = [[%c(NextUpDashBoardAdjunctItemView) alloc] initWithRecipe:0 options:0]; // initWithRecipe:1 options:2
            self.nextUpContainerView.contentHost = self.nextUpViewController;
            self.nextUpContainerView.alpha = 0.0;
            self.nextUpContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);

            self.nextUpViewController.containerView = self.nextUpContainerView;

            // self.hapticGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

            self.nextUpInitialized = YES;
        }
    }

    %new
    - (void)insertNextUpSubviewAtEnd {
        UIStackView *_stackView = [self valueForKey:@"_stackView"];
        [_stackView insertArrangedSubview:self.nextUpContainerView atIndex:1];
    }

    %new
    - (void)showNextUp {
        [self insertNextUpSubviewAtEnd];

        UIStackView *_stackView = [self valueForKey:@"_stackView"];
        [_stackView addArrangedSubview:self.nextUpContainerView];
        [UIView animateWithDuration:0.375
                              delay:0.0
                            options:nil
                         animations: ^{
                            self.nextUpContainerView.alpha = 1.0;
                            self.nextUpContainerView.transform = CGAffineTransformMakeScale(1, 1);
                        }
                         completion: ^(BOOL finished) {
                            self.showingNextUp = YES;
                        }
        ];
    }

    %new
    - (void)hideNextUp {
        [UIView animateWithDuration:0.375
                              delay:0.0
                            options:nil
                         animations: ^{
                            self.nextUpContainerView.alpha = 0.0;
                            self.nextUpContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                        }
                         completion: ^(BOOL finished) {
                            UIStackView *_stackView = [self valueForKey:@"_stackView"];
                            [_stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
                            [_stackView removeArrangedSubview:self.nextUpContainerView];
                            self.showingNextUp = NO;
                        }
        ];
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

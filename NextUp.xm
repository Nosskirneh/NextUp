#import "NextUpManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Common.h"
#import "Spotify.h"
#import "Deezer.h"
#import "Music.h"
#import "Podcasts.h"
#import "YTMusic.h"
#import "SoundCloud.h"
#import "PlayMusic.h"
#import "TIDAL.h"
#import "Anghami.h"
#import "Headers.h"
#import "DRMOptions.mm"


NextUpManager *manager;


/* Anghami */
%group Anghami
    ANGPlayQueue *getQueue() {
        return [%c(PlayQueueSingleton) currentPlayQueue];
    }

    void ANGSkipNext(notificationArguments) {
        [getQueue() skipNext];
    }

    void ANGManualUpdate(notificationArguments) {
        [getQueue() manuallyUpdate];
    }

    %hook ANGPlayQueue
    %property (nonatomic, retain) ANGSong *lastSentTrack;

    - (void)setIsShuffled:(BOOL)shuffle keepSameSong:(BOOL)keep {
        %orig;

        [self fetchNextUp];
    }

    // This seems to be called on all usable methods in PlayQueueSingleton (move, add, clear etc)
    - (BOOL)setCurrentIndex:(unsigned long long)index userAction:(BOOL)userAction report:(BOOL)report {
        BOOL orig = %orig;
        [self fetchNextUp];

        return orig;
    }

    %new
    - (void)manuallyUpdate {
        self.lastSentTrack = nil;
        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        if (!self.nextSong)
            return sendNextTrackMetadata(nil);

        ANGSong *item = self.nextSong;

        if ([item isEqual:self.lastSentTrack])
            return;

        self.lastSentTrack = item;


        ANGImageDownloadSpec *spec = [item imageDownloadSpecWithSize:ARTWORK_SIZE.width];
        ANGImageDownloader *imageDownloader = [%c(ANGImageDownloader) sharedInstance];
        [imageDownloader getImage:spec callback:^(void) {
            BOOL thumbnail = YES;
            UIImage *image = [imageDownloader imageFromCacheForSpec:spec thumbnail:&thumbnail];
            NSDictionary *metadata = [self serializeTrack:item image:image];
            sendNextTrackMetadata(metadata);
        }];
    }

    %new
    - (NSDictionary *)serializeTrack:(ANGSong *)item image:(UIImage *)image {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        metadata[kTitle] = item.title;
        metadata[kSubtitle] = item.artistName;

        if (image)
            metadata[kArtwork] = UIImagePNGRepresentation(image);

        return metadata;
    }

    %new
    - (void)skipNext {
        if (self.nextSong)
            [%c(PlayQueueSingleton) removeSongFromQueue:self.nextSong];
    }

    %end
%end
// ---


/* TIDAL */
%group TIDAL
    void TDLSkipNext(notificationArguments) {
        [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] skipNext];
    }

    void TDLManualUpdate(notificationArguments) {
        [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] manuallyUpdate];
    }

    %hook _TtC4WiMP16PlayQueueManager
    %property (nonatomic, retain) WMPImageService *imageService;
    %property (nonatomic, retain) _TtC4WiMP13PlayQueueItem *lastSentTrack;

    - (id)init {
        _TtC4WiMP16PlayQueueManager *orig = %orig;
        orig.imageService = [[%c(WMPImageService) alloc] init];

        return orig;
    }

    %new
    - (void)manuallyUpdate {
        self.lastSentTrack = nil;
        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        if (!self.nextItem)
            return sendNextTrackMetadata(nil);

        _TtC4WiMP13PlayQueueItem *item = self.nextItem;

        if ([item isEqual:self.lastSentTrack])
            return;

        self.lastSentTrack = item;
        NSDictionary *metadata = [self serializeTrack:item];
        sendNextTrackMetadata(metadata);
    }

    %new
    - (NSDictionary *)serializeTrack:(_TtC4WiMP13PlayQueueItem *)item {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        metadata[kTitle] = item.title;
        metadata[kSubtitle] = item.artistTitle;

        UIImage *image = [self.imageService imageForAlbumId:@(item.albumId) withImageResourceId:item.imageResourceId size:8];
        if (!image)
            image = [self.imageService getDefaultAlbumImageForSize:8];

        metadata[kArtwork] = UIImagePNGRepresentation(image);

        return metadata;
    }

    %new
    - (void)skipNext {
        if (self.nextItem)
            [self removeItemAtIndex:self.currentPosition + 1];
    }

    %end

    // This is called on next track, toggling shuffle, reordering, adding or removing to/from the queue.
    %hook _TtC4WiMP15PlayQueueModule

    - (void)playQueueDidChange:(id)arg1 {
        %orig;

        [[%c(_TtC4WiMP16PlayQueueManager) sharedInstance] fetchNextUp];
    }

    %end
%end
// ---


/* Google Music */
%group PlayMusic
    AppDelegate *getGPMAppDelegate() {
        return (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }

    GPMImageFetcher *getImageFetcher() {
        return getGPMAppDelegate().appServiceManager.imageFetcher;
    }

    MusicQueueManager *getQueueManager() {
        return getGPMAppDelegate().musicQueueManager;
    }

    void GPMSkipNext(notificationArguments) {
        [getQueueManager() skipNext];
    }

    void GPMManualUpdate(notificationArguments) {
        [getQueueManager() manuallyUpdate];
    }

    %hook MusicQueueManager
    %property (nonatomic, retain) Track *lastSentTrack;

    - (void)updatePlayState {
        %orig;

        [self fetchNextUp];
    }

    // This is called when reordering the queue, removing or adding something to/from it
    - (void)updateCurrentTrackAndIndex {
        %orig;

        [self fetchNextUp];
    }

    %new
    - (void)manuallyUpdate {
        self.lastSentTrack = nil;
        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        if (!self.hasNext)
            return sendNextTrackMetadata(nil);

        Track *track = self.tracks[self.currentTrackIndex + 1];
        if ([track isEqual:self.lastSentTrack])
            return;

        self.lastSentTrack = track;

        NSURL *artworkURL = [NSURL URLWithString:track.albumArtURLString];
        [getImageFetcher() fetchImageWithURL:artworkURL size:ARTWORK_SIZE quality:1 operationSequence:[%c(GPMOperationSequence) new] completionHandler:^(UIImage *image) {
            NSDictionary *metadata = [self serializeTrack:track image:image];
            sendNextTrackMetadata(metadata);
        }];
    }

    %new
    - (NSDictionary *)serializeTrack:(Track *)track image:(UIImage *)image {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        metadata[kTitle] = track.title;
        metadata[kSubtitle] = track.albumArtistString;

        if (image)
            metadata[kArtwork] = UIImagePNGRepresentation(image);

        return metadata;
    }

    %new
    - (void)skipNext {
        if (self.hasNext)
            [self removeTrackAtIndex:self.currentTrackIndex + 1];
    }

    %end
%end


/* SoundCloud */
%group SoundCloud
    void SDCManualUpdate(notificationArguments) {
        [[%c(PlaybackService) sharedInstance] fetchNextUp];
    }

    %hook _TtC2UI11ImageLoader

    - (id)initWithPlaceholder:(id)arg1 {
        PlaybackService *playbackService = [%c(PlaybackService) sharedInstance];
        if (!playbackService.imageLoader)
            return playbackService.imageLoader = %orig;
        return %orig;
    }

    %end

    %hook PlaybackService
    %property (nonatomic, retain) _TtC2UI11ImageLoader *imageLoader;

    - (void)preloadItemAfterItem:(id)arg1 {
        %orig;
        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        _TtC8Playback10PlayerItem *item = [self nextItemWithInteraction:0];

        if (!item)
            return;

        [self.imageLoader loadImageFrom:item.artworkURL successCompletion:^(UIImage *image) {
            NSDictionary *metadata = [self serializeTrack:item image:image skipable:NO];
            sendNextTrackMetadata(metadata);
        } failureCompletion:nil];
    }

    %new
    - (NSDictionary *)serializeTrack:(_TtC8Playback10PlayerItem *)item image:(UIImage *)image skipable:(BOOL)skipable {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        metadata[kTitle] = item.title;
        metadata[kSubtitle] = item.artistName;
        metadata[kSkipable] = @(skipable);

        if (image)
            metadata[kArtwork] = UIImagePNGRepresentation(image);

        return metadata;
    }

    %end
%end
// ---


/* YouTube Music */
%group YTMusic
    void YTMSkipNext(notificationArguments) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kYTMSkipNext object:nil];
    }

    void YTMManualUpdate(notificationArguments) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kYTMManualUpdate object:nil];
    }

    YTMAppDelegate *getYTMAppDelegate() {
        return (YTMAppDelegate *)[[UIApplication sharedApplication] delegate];
    }

    GIMMe *gimme() {
        return getYTMAppDelegate().gimme;
    }

    %hook YTMQueueController

    - (void)commonInit {
        %orig;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(skipNext)
                                                     name:kYTMSkipNext
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fetchNextUp)
                                                     name:kYTMManualUpdate
                                                   object:nil];
    }

    - (unsigned long long)addQueueItems:(NSArray *)items numItemsToReveal:(long long)reveal atIndex:(unsigned long long)index {
        unsigned long long orig = %orig;

        if (index == self.nextVideoIndex)
            [self fetchNextUp];

        return orig;
    }

    - (void)moveItemAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
        %orig;

        if (from.row == self.nextVideoIndex || to.row == self.nextVideoIndex)
            [self fetchNextUp];
    }

    - (void)removeVideoAtIndex:(unsigned long long)index {
        %orig;

        if (index == self.nextVideoIndex)
            [self fetchNextUp];
    }

    - (void)automixController:(id)controller didRemoveRenderersAtIndexes:(NSIndexSet *)indexes {
        %orig;

        if ([indexes containsIndex:self.nextVideoIndex])
            [self fetchNextUp];
    }

    - (void)automixController:(id)controller didInsertRenderersAtIndexes:(NSIndexSet *)indexes response:(id)arg3 {
        %orig;

        if ([indexes containsIndex:self.nextVideoIndex])
            [self fetchNextUp];
    }

    - (void)setAutoExtendPlaybackQueueEnabled:(BOOL)enable {
        %orig;

        [self fetchNextUp];
    }

    - (void)playItemAtIndex:(unsigned long long)index autoPlaySource:(int)autoplay atStartTime:(double)starttime {
        %orig;

        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        YTIPlaylistPanelVideoRenderer *next = self.nextVideo;

        if (next && next.hasThumbnail && next.thumbnail.thumbnailsArray.count > 0) {
            NSArray *thumbnails = next.thumbnail.thumbnailsArray;
            YTIThumbnailDetails_Thumbnail *pickedThumbnail;
            // Find the closest to the size
            for (YTIThumbnailDetails_Thumbnail *thumbnail in thumbnails) {
                pickedThumbnail = thumbnail;
                if (thumbnail.height >= ARTWORK_SIZE.height * [UIScreen mainScreen].scale)
                    break;
            }

            NSString *URL = pickedThumbnail.URL;

            YTImageServiceImpl *imageService = [gimme() instanceForType:%c(YTImageService)];
            [imageService makeImageRequestWithURL:[NSURL URLWithString:URL] responseBlock:^(UIImage *image) {
                NSDictionary *metadata = [self serializeTrack:next image:image];
                sendNextTrackMetadata(metadata);
            } errorBlock:nil];
        } else {
            sendNextTrackMetadata(nil);
        }
    }

    %new
    - (NSDictionary *)serializeTrack:(YTIPlaylistPanelVideoRenderer *)item image:(UIImage *)image {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        if (item.hasTitle)
            metadata[kTitle] = [item.title accessibilityLabel];

        if (item.hasShortBylineText)
            metadata[kSubtitle] = [item.shortBylineText accessibilityLabel];

        if (image)
            metadata[kArtwork] = UIImagePNGRepresentation(image);

        if (self.nowPlayingIndex + 1 == self.queueCount)
            metadata[kSkipable] = @NO;

        return metadata;
    }

    %new
    - (void)skipNext {
        [self removeVideoAtIndex:self.nextVideoIndex];
    }

    %end
%end
// ---


/* Podcasts */
%group Podcasts
    void PODSkipNext(notificationArguments) {
        [[%c(MTPlaybackQueueController) sharedInstance] skipNext];
    }

    void PODManualUpdate(notificationArguments) {
        MTPlaybackQueueController *queueController = [%c(MTPlaybackQueueController) sharedInstance];
        queueController.lastSentEpisode = nil;
        [queueController fetchNextUp];
    }


    %hook MTAppDelegate_Shared

    - (BOOL)application:(id)arg didFinishLaunchingWithOptions:(id)options {
        [%c(MTPlaybackQueueController) sharedInstance]; // Makes sure its init method gets called
        return %orig;
    }

    %end

    %hook MTPlaybackQueueController
    %property (nonatomic, retain) MTPlayerItem *lastSentEpisode;

    - (id)init {
        MTPlaybackQueueController *orig = %orig;

        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(fetchNextUp)
                                                     name:@"IMPlayerManifestDidChange"
                                                   object:nil];
        return orig;
    }

    %new
    - (NSDictionary *)serializeTrack:(MTPlayerItem *)item image:(UIImage *)image skipable:(BOOL)skipable {
        NSMutableDictionary *metadata = [NSMutableDictionary new];

        metadata[kTitle] = item.title;
        metadata[kSubtitle] = item.subtitle;
        metadata[kSkipable] = @(skipable);

        if (image)
            metadata[kArtwork] = UIImagePNGRepresentation(image);

        return metadata;
    }

    %new
    - (MTCompositeManifest *)getManifest {
        if ([self respondsToSelector:@selector(manifest)])
            return self.manifest;
        else if ([self respondsToSelector:@selector(compositeManifest)])
            return self.compositeManifest;
        return nil;
    }

    %new
    - (void)manuallyUpdate {
        self.lastSentEpisode = nil;
        [self fetchNextUp];
    }

    %new
    - (void)fetchNextUp {
        MTCompositeManifest *manifest = [self getManifest];

        MTPlayerItem *item = nil;
        int nextIndex = manifest.currentIndex + 1;
        if (manifest.currentIndex == LONG_MAX)
            nextIndex = 1;

        if ([manifest count] > nextIndex) {
            BOOL skipable = manifest.upNextManifest.count > 0 &&
                            !(manifest.upNextManifest.count == 1 && manifest.isPlayingFromUpNext);
            item = [manifest objectAtIndex:nextIndex];
            [self fetchNextUpFromItem:item skipable:skipable];
        } else {
            sendNextTrackMetadata(nil);
        }
        self.lastSentEpisode = item;
    }

    %new
    - (void)fetchNextUpFromItem:(MTPlayerItem *)item skipable:(BOOL)skipable {
        // Since manual updates are coming from SpringBoard when the
        // current now playing app changed to Podcasts, this would otherwise
        // happen twice (due to the IMPlayerManifestDidChange notification).
        if ([self.lastSentEpisode isEqual:item])
            return;

        [item retrieveArtwork:^(UIImage *image) {
            NSDictionary *metadata = [self serializeTrack:item image:image skipable:skipable];
            sendNextTrackMetadata(metadata);
        } withSize:ARTWORK_SIZE];
    }

    %new
    - (void)skipNext {
        MTCompositeManifest *manifest = [self getManifest];
        int nextIndex = manifest.currentIndex + 1;
        if ([manifest count] > nextIndex) {
            // This only work with items that were manually queued;
            // seems to be a limiation in how the Podcasts app is built.
            BOOL removed = NO;
            if ([self respondsToSelector:@selector(nowPlayingInfoCenter:removeItemAtOffset:)]) {
                MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter infoCenterForPlayerID:@"Podcasts"];
                removed = [self nowPlayingInfoCenter:infoCenter removeItemAtOffset:nextIndex];
            } else if ([self respondsToSelector:@selector(removeItemWithContentID:)]) {
                MTPlayerItem *item = [manifest objectAtIndex:nextIndex];
                removed = [self removeItemWithContentID:[item contentItemIdentifier]];
            }

            if (removed)
                [self fetchNextUp];
        }
    }

    %end
%end
// ---


/* Music */
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
            metadata[kTitle] = [item mainTitle];
        else if ([item isKindOfClass:%c(MPMediaItem)]) {
            metadata[kTitle] = item.title;

            if (!image)
                artwork = [item.artwork imageWithSize:ARTWORK_SIZE];
        }

        metadata[kSubtitle] = item.artist;

        metadata[kArtwork] = UIImagePNGRepresentation(artwork);
        return metadata;
    }

    %new
    - (void)fetchNextUpItem:(MPMediaItem *)item withArtworkCatalog:(block)artworkBlock {
        MPArtworkCatalog *catalog = artworkBlock();

        [catalog setFittingSize:ARTWORK_SIZE];
        catalog.destinationScale = [UIScreen mainScreen].scale;

        [catalog requestImageWithCompletionHandler:^(UIImage *image) {
            NSDictionary *metadata = [self serializeTrack:item image:image];
            sendNextTrackMetadata(metadata);
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
        queueViewModel.lastSentTrack = nil;
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
    %property (nonatomic, retain) SPTPlayerTrack *lastSentTrack;

    - (void)player:(SPTPlayerImpl *)player stateDidChange:(SPTPlayerState *)newState fromState:(SPTPlayerState *)oldState {
        %orig;

        [self fetchNextUpForState:newState];
    }

    %new
    - (void)fetchNextUpForState:(SPTPlayerState *)state {
        NSArray<SPTPlayerTrack *> *next = state.future;
        if (next.count > 0) {
            if (![next[0] isEqual:self.lastSentTrack])
                [self sendNextUpMetadata:next[0]];
            return;
        }
        
        sendNextTrackMetadata(nil);
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
        self.lastSentTrack = track;

        NSMutableDictionary *metadata = [NSMutableDictionary new];
        metadata[kTitle] = [track trackTitle];
        metadata[kSubtitle] = track.artistTitle;

        // Artwork
        CGSize imageSize = ARTWORK_SIZE;
        __block UIImage *image = [UIImage trackSPTPlaceholderWithSize:0];

        // Do this lastly
        if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
            [self.imageLoader loadImageForURL:track.coverArtURL imageSize:imageSize completion:^(UIImage *img) {
                if (img)
                    image = img;

                metadata[kArtwork] = UIImagePNGRepresentation(image);
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

    void DZRManualUpdate(notificationArguments) {
        [getMixQueuer() fetchNextUp];
    }

    DZRMixQueuer *getMixQueuer() {
        return [%c(DZRAudioPlayer) sharedPlayer].queuer;
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
        metadata[kTitle] = track.title;
        metadata[kSubtitle] = track.artistName;
        UIImage *artwork = image;
        // `nowPlayingArtwork` has to be fetched. It doesn't exist a method to do that
        // with a completionhandler, so I've implemented this in DeezerTrack below
        if (!artwork)
            artwork = [track.nowPlayingArtwork imageWithSize:ARTWORK_SIZE];
        metadata[kArtwork] = UIImagePNGRepresentation(artwork);
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
    /* Listen on changes of now playing app */
    %hook SBMediaController
    %property (nonatomic, retain) NSDictionary *nextUpPrefs;

    - (id)init {
        SBMediaController *orig = %orig;
        orig.nextUpPrefs = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

        return orig;
    }

    %new
    - (BOOL)isValidApplicationID:(NSString *)bundleID {
        return !self.nextUpPrefs[bundleID] || [self.nextUpPrefs[bundleID] boolValue];
    }

    - (void)_setNowPlayingApplication:(SBApplication *)app {
        NSString *bundleID = app.bundleIdentifier;
        if ([manager.enabledApps containsObject:app.bundleIdentifier] && [self isValidApplicationID:app.bundleIdentifier]) {
            [manager setMediaApplication:bundleID];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowNextUp object:nil];
        } else {
            [manager setMediaApplication:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kHideNextUp object:nil];
        }

        %orig;
    }

    %end

    /* Control Center */
    %hook MediaControlsPanelViewController

    %property (nonatomic, assign, getter=isNextUpInitialized) BOOL nextUpInitialized;

    - (void)setDelegate:(id)delegate {
        %orig;

        if ([self NU_isControlCenter])
            [self initNextUp];
    }

    - (void)setStyle:(int)style {
        %orig;

        if ([self NU_isControlCenter]) {
            MediaControlsContainerView *containerView = self.parentContainerView.mediaControlsContainerView;
            containerView.nextUpViewController.style = style;
        }
    }

    %new
    - (BOOL)NU_isControlCenter {
        return ([self.delegate class] == %c(MediaControlsEndpointsViewController));
    }

    %new
    - (void)initNextUp {
        if (![self isNextUpInitialized]) {
            MediaControlsContainerView *containerView = self.parentContainerView.mediaControlsContainerView;

            [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                     selector:@selector(showNextUp)
                                                         name:kShowNextUp
                                                       object:nil];

            [[NSNotificationCenter defaultCenter] addObserver:containerView
                                                     selector:@selector(hideNextUp)
                                                         name:kHideNextUp
                                                       object:nil];

            containerView.nextUpViewController = [[%c(NextUpViewController) alloc] init];
            containerView.nextUpViewController.cornerRadius = 15;
            containerView.nextUpViewController.manager = manager;
            containerView.nextUpViewController.controlCenter = YES;

            self.nextUpInitialized = YES;
        }
    }

    %end

    %hook CCUIContentModuleContainerViewController

    - (void)setExpanded:(BOOL)expanded {
        %orig;

        if ([self.moduleIdentifier isEqualToString:@"com.apple.mediaremote.controlcenter.nowplaying"])
            manager.controlCenterExpanded = expanded;
    }

    %end

    %hook MediaControlsContainerView

    %property (nonatomic, retain) NextUpViewController *nextUpViewController;
    %property (nonatomic, assign, getter=isShowingNextUp) BOOL showingNextUp;
    %property (nonatomic, assign) BOOL shouldShowNextUp;

    - (void)layoutSubviews {
        %orig;

        if (manager.controlCenterExpanded && self.shouldShowNextUp) {
            CGRect frame = self.frame;
            frame.size.height = 101.0;
            self.frame = frame;

            self.nextUpViewController.view.frame = CGRectMake(self.frame.origin.x,
                                                              self.frame.origin.y + self.frame.size.height,
                                                              self.frame.size.width,
                                                              105);

            if (!self.showingNextUp)
                [self addNextUpView];
        }
    }

    %new
    - (void)addNextUpView {
        [self.superview addSubview:self.nextUpViewController.view];

        self.showingNextUp = YES;
    }

    %new
    - (void)showNextUp {
        self.shouldShowNextUp = YES;
        [self layoutSubviews];
    }

    %new
    - (void)hideNextUp {
        self.shouldShowNextUp = NO;
        [self layoutSubviews];
    }

    %end
    // ---


    /* Lockscreen */
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

    // Fixes bug when quickly showing the widget again where it would be cut off
    - (void)viewDidLayoutSubviews {
        %orig;

        UIView *itemView = MSHookIvar<UIView *>(self, "_nowPlayingControlsItem");
        CGRect frame = itemView.frame;
        frame.size.height += frame.origin.y;
        frame.origin.y = 0;
        itemView.frame = frame;
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

            BOOL noctisEnabled = NO;
            if (%c(NoctisSystemController)) {
                NSDictionary *noctisPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laughingquoll.noctisxiprefs.settings.plist"];
                noctisEnabled = !noctisPrefs || [noctisPrefs[@"enableMedia"] boolValue];
                self.nextUpViewController.noctisEnabled = noctisEnabled;
            }

            MediaControlsPanelViewController *panelViewController = MSHookIvar<MediaControlsPanelViewController *>(self, "_mediaControlsPanelViewController");
            self.nextUpViewController.style = noctisEnabled ? 2 : panelViewController.style;
            self.nextUpViewController.cornerRadius = 15;
            self.nextUpViewController.manager = manager;

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
    // ---
%end
// ---


/* ColorFlow 4 support */
%group ColorFlow
    %hook SBDashBoardMediaControlsViewController
    - (void)cfw_colorize:(CFWColorInfo *)colorInfo {
        %orig;

        self.nextUpViewController.mediaView.routingButton.tintColor = colorInfo.primaryColor;
        self.nextUpViewController.headerLabel.textColor = colorInfo.primaryColor;
        [self.nextUpViewController.mediaView cfw_colorize:colorInfo];
    }

    - (void)cfw_revert {
        %orig;

        self.nextUpViewController.mediaView.routingButton.tintColor = UIColor.whiteColor;
        self.nextUpViewController.headerLabel.textColor = UIColor.whiteColor;
        [self.nextUpViewController.mediaView cfw_revert];
    }
    %end
%end
// ---


/* Custom views */
%group CustomViews
    #define DIGITAL_TOUCH_BUNDLE [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/DigitalTouchShared.framework"]

    %subclass NULabel : UILabel

    - (void)setAlpha:(CGFloat)alpha {
        %orig(0.63);
    }

    %end

    %subclass NUSkipButton : UIButton

    - (void)setUserInteractionEnabled:(BOOL)enabled {
        %orig(YES);
    }

    - (void)setAlpha:(CGFloat)alpha {
        %orig(0.95);
    }

    %end


    %subclass NextUpMediaHeaderView : MediaControlsHeaderView

    // Override routing button
    %property (nonatomic, retain) NUSkipButton *routingButton;
    %property (nonatomic, retain) NULabel *primaryLabel;
    %property (nonatomic, retain) NULabel *secondaryLabel;

    - (id)initWithFrame:(CGRect)arg1 {
        NextUpMediaHeaderView *orig = %orig;

        orig.routingButton = [%c(NUSkipButton) buttonWithType:UIButtonTypeSystem];
        UIImage *image = [UIImage imageNamed:@"Cancel.png" inBundle:DIGITAL_TOUCH_BUNDLE];
        [orig.routingButton setImage:image forState:UIControlStateNormal];
        [orig addSubview:orig.routingButton];

        orig.primaryLabel = [[%c(NULabel) alloc] initWithFrame:CGRectZero];
        orig.secondaryLabel = [[%c(NULabel) alloc] initWithFrame:CGRectZero];
        [orig.primaryMarqueeView.contentView addSubview:orig.primaryLabel];
        [orig.secondaryMarqueeView.contentView addSubview:orig.secondaryLabel];

        return orig;
    }

    - (void)layoutSubviews {
        %orig;

        CGRect frame = self.primaryMarqueeView.frame;
        float maxWidth = self.routingButton.frame.origin.x - self.artworkView.frame.origin.x - self.artworkView.frame.size.width - 15;
        if (self.routingButton.hidden)
            maxWidth += self.routingButton.frame.size.width;

        float primaryMaxWidth = fmin(frame.size.width, maxWidth);
        frame.size.width = primaryMaxWidth;
        self.primaryMarqueeView.frame = frame;

        frame = self.secondaryMarqueeView.frame;
        float secondaryMaxWidth = fmin(frame.size.width, maxWidth);
        frame.size.width = secondaryMaxWidth;
        self.secondaryMarqueeView.frame = frame;

        self.buttonBackground.hidden = YES;
    }

    %end
%end
// ---


%group Welcome
%hook SBLockScreenManager

- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
    BOOL orig = %orig;
    UIViewController *root = [[UIApplication sharedApplication] keyWindow].rootViewController;

    if ([root isKindOfClass:%c(SBHomeScreenViewController)])
        OBFS_UIALERT(root, packageShown$bs(), WelcomeMsg$bs(), OK$bs());

    return orig;
}

%end
%end


%ctor {
    // License check – if no license found, present message. If no valid license found, do not init
    switch (check_lic(licensePath$bs(), package$bs())) {
        case CheckNoLicense:
            if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:kSpringBoardBundleID])
                %init(Welcome);
            return;
        case CheckInvalidLicense:
            return;
        case CheckValidLicense:
            break;
        case CheckUDIDsDoNotMatch:
            return;
    }
    // ---

    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if ([bundleID isEqualToString:kSpringBoardBundleID]) {
        %init(SpringBoard);
        %init(ColorFlow);
        %init(CustomViews);
        manager = [[NextUpManager alloc] init];
    } else {
        if (preferences[bundleID] && ![preferences[bundleID] boolValue])
            return;

        if ([bundleID isEqualToString:kSpotifyBundleID]) {
            %init(Spotify);
            subscribe(&SPTSkipNext, kSPTSkipNext);
            subscribe(&SPTManualUpdate, kSPTManualUpdate);
        } else if ([bundleID isEqualToString:kMusicBundleID]) {
            %init(Music);
            subscribe(&APMSkipNext, kAPMSkipNext);
            subscribe(&APMManualUpdate, kAPMManualUpdate);
        } else if ([bundleID isEqualToString:kDeezerBundleID]) {
            %init(Deezer);
            subscribe(&DZRSkipNext, kDZRSkipNext);
            subscribe(&DZRManualUpdate, kDZRManualUpdate);
        } else if ([bundleID isEqualToString:kPodcastsBundleID]) {
            %init(Podcasts);
            subscribe(&PODSkipNext, kPODSkipNext);
            subscribe(&PODManualUpdate, kPODManualUpdate);
        } else if ([bundleID isEqualToString:kYoutubeMusicBundleID]) {
            %init(YTMusic);
            subscribe(&YTMSkipNext, kYTMSkipNext);
            subscribe(&YTMManualUpdate, kYTMManualUpdate);
        } else if ([bundleID isEqualToString:kSoundCloudBundleID]) {
            %init(SoundCloud);
            subscribe(&SDCManualUpdate, kSDCManualUpdate);
        } else if ([bundleID isEqualToString:kPlayMusicBundleID]) {
            %init(PlayMusic);
            subscribe(&GPMSkipNext, kGPMSkipNext);
            subscribe(&GPMManualUpdate, kGPMManualUpdate);
        } else if ([bundleID isEqualToString:kTIDALBundleID]) {
            %init(TIDAL);
            subscribe(&TDLSkipNext, kTDLSkipNext);
            subscribe(&TDLManualUpdate, kTDLManualUpdate);
        } else {
            HBLogDebug(@"init Anghami");
            %init(Anghami);
            subscribe(&ANGSkipNext, kANGSkipNext);
            subscribe(&ANGManualUpdate, kANGManualUpdate);
        }
    }
}

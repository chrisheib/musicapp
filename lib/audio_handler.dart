import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/main.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.chrisheib.musicapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

Future<void> initAudioServiceHandler() async {
  GetIt.I.registerSingleton<AudioHandler>(await initAudioService());
}

class SingletonConfig {
  bool skip = false;
  bool pause = false;
  bool play = false;
  bool upvote = false;
  bool downvote = false;
  MediaItem? mediaItem;
  int rating = 0;
}

SingletonConfig getConfig() {
  return GetIt.I<SingletonConfig>();
}

AudioHandler getAudioHandler() {
  return GetIt.I<AudioHandler>();
}

MyAudioHandler getMyAudioHandler() {
  return GetIt.I<MyAudioHandler>();
}

Future<void> setSkip() async {
  getConfig().skip = true;
}

Future<void> setPause() async {
  getConfig().pause = true;
}

Future<void> setPlay() async {
  getConfig().play = true;
}

Future<void> setUpvote() async {
  getConfig().upvote = true;
}

Future<void> setDownvote() async {
  getConfig().downvote = true;
}

Future<void> mySetRating(int rating) async {
  getConfig().rating = rating;
}

AudioPlayer initAudioPlayer() {
  var player = AudioPlayer();
  GetIt.I.registerSingleton(player);
  return player;
}

void setNotificationRating(int rating) {
  logger.info("set notification rating: $rating");
  mySetRating(rating);
  getMyAudioHandler().setControlsFromRating(rating);
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = initAudioPlayer();
  final _config = getConfig();

  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    GetIt.I.registerSingleton(this);
  }

  void setMediaItem(MediaItem newMediaItem) async {
    logger.info("Add media item");
    if (newMediaItem.extras?["rating"] != null) {
      logger.info("Add media item, rating: ${newMediaItem.extras?["rating"].toString() ?? ""}");
      setNotificationRating(newMediaItem.extras?["rating"]);
    }
    mediaItem.add(newMediaItem);
  }

  void setControlsFromRating(int rating) {
    logger.info("Set Controls From rating: $rating");
    final playing = _player.playing;
    var pb = playbackState.value.copyWith(
      controls: getControls(rating, playing),
      updatePosition: _player.position
    );
    playbackState.add(pb);
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.loading) {
        if (_config.mediaItem != null) {
          logger.info(_config.mediaItem.toString());
          setMediaItem(_config.mediaItem!);
          _config.mediaItem = null;
        }
      }
      if (processingState == ProcessingState.ready) {
        var m = mediaItem.value;
        if (m != null) {
          logger.info(m.toString());
          var m2 = m.copyWith(duration: _player.duration);
          setMediaItem(m2);
        }
      }
    });

    _player.playbackEventStream.listen((PlaybackEvent event) {
      logger.info("Playbackeventstream event: ${event.toString()}");
      final playing = _player.playing;
      final rating = getConfig().rating;
      var pb = playbackState.value.copyWith(
        controls: getControls(rating, playing),
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [
          0,
        ],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
      );
      playbackState.add(pb);
    });
  }


  @override
  Future<void> play() => setPlay();

  @override
  Future<void> pause() => setPause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => setSkip();

  @override
  Future<void> skipToPrevious() async {
    setUpvote();
    logger.info("skipToPrevious -> upvote");
  }

  @override
  Future<void> stop() async {
    // setDownvote();
    logger.info("stop -> downvote");
  }

  @override
  Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) async {
    logger.info("Rating: ${rating.toString()}, extras: ${extras.toString()}");
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.stop();
    } 

    if (name == 'like') {
      setUpvote();
    }

    if (name == 'dislike') {
      setDownvote();
    }

    logger.info("Custom Action: $name, extras: ${extras.toString()}");
  }

  static MediaControl like = MediaControl.custom(
    androidIcon: 'drawable/up',
    label: 'Like',
    name: 'like',
  );

  static MediaControl dislike = MediaControl.custom(
    androidIcon: 'drawable/down',
    label: 'Dislike',
    name: 'dislike'
  );

  static MediaControl oneStar = MediaControl.custom(
    androidIcon: 'drawable/one',
    label: 'Star',
    name: 'star'
  );

  static MediaControl twoStar = MediaControl.custom(
    androidIcon: 'drawable/two',
    label: 'Star',
    name: 'star'
  );

  static MediaControl threeStar = MediaControl.custom(
    androidIcon: 'drawable/three',
    label: 'Star',
    name: 'star'
  );

  static MediaControl fourStar = MediaControl.custom(
    androidIcon: 'drawable/four',
    label: 'Star',
    name: 'star'
  );

  static MediaControl fiveStar = MediaControl.custom(
    androidIcon: 'drawable/five',
    label: 'Star',
    name: 'star'
  );

  static MediaControl sixStar = MediaControl.custom(
    androidIcon: 'drawable/six',
    label: 'Star',
    name: 'star'
  );

  static MediaControl sevenStar = MediaControl.custom(
    androidIcon: 'drawable/seven',
    label: 'Star',
    name: 'star'
  );
  
  List<MediaControl> getControls(int rating, bool playing) {
    return [  
      dislike,
      like,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      if (rating >= 1 && rating <= 7) ratingToControl(rating),
    ];
  }

  MediaControl ratingToControl(int rating) {
    switch (rating) {
      case 1:
        return oneStar;
      case 2:
        return twoStar;
      case 3:
        return threeStar;
      case 4:
        return fourStar;
      case 5:
        return fiveStar;
      case 6:
        return sixStar;
      case 7:
        return sevenStar;
      default:
        return oneStar;
    }
  }
}

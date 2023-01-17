import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';

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
    print("Add media item");
    if (newMediaItem.extras?["rating"] != null) {
      print("Add media item, rating: " +
          (newMediaItem.extras?["rating"].toString() ?? ""));
      setNotificationRating(newMediaItem.extras?["rating"]);
    }
    mediaItem.add(newMediaItem);
  }

  void setControlsFromRating(int rating) {
    final playing = _player.playing;
    var pb = playbackState.value.copyWith(controls: [
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      like,
      dislike,
    ]);
    var ratingC = ratingToControl(rating);
    if (ratingC != null) {
      pb.controls.add(ratingC);
    }
    playbackState.add(pb);
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.loading) {
        if (_config.mediaItem != null) {
          print(_config.mediaItem.toString());
          setMediaItem(_config.mediaItem!);
          _config.mediaItem = null;
        }
      }
      if (processingState == ProcessingState.ready) {
        var m = mediaItem.value;
        if (m != null) {
          print(m.toString());
          var m2 = m.copyWith(duration: _player.duration);
          setMediaItem(m2);
        }
      }
    });

    _player.playbackEventStream.listen((PlaybackEvent event) {
      // print("Playbackeventstream event: ${event.toString()}");
      final playing = _player.playing;
      var pb = playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          like,
          dislike,
        ],
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
      var ratingC = ratingToControl(getConfig().rating);
      if (ratingC != null) {
        pb.controls.add(ratingC);
      }
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
    print("skipToPrevious -> upvote");
  }

  @override
  Future<void> stop() async {
    setDownvote();
    print("stop -> downvote");
  }

  @override
  Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) async {
    print("Rating: ${rating.toString()}, extras: ${extras.toString()}");
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.stop();
    }

    print("Custom Action: $name, extras: ${extras.toString()}");
  }

  static MediaControl like = const MediaControl(
    androidIcon: 'drawable/thumbs_up',
    label: 'Like',
    action: MediaAction.skipToPrevious,
  );

  static MediaControl dislike = const MediaControl(
    androidIcon: 'drawable/thumbs_down',
    label: 'Dislike',
    action: MediaAction.stop,
  );

  static MediaControl oneStar = const MediaControl(
    androidIcon: 'drawable/onestar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  static MediaControl twoStar = const MediaControl(
    androidIcon: 'drawable/twostar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  static MediaControl threeStar = const MediaControl(
    androidIcon: 'drawable/threestar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  static MediaControl fourStar = const MediaControl(
    androidIcon: 'drawable/fourstar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  static MediaControl fiveStar = const MediaControl(
    androidIcon: 'drawable/fivestar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  static MediaControl sixStar = const MediaControl(
    androidIcon: 'drawable/sixstar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  static MediaControl sevenStar = const MediaControl(
    androidIcon: 'drawable/sevenstar',
    label: 'Dislike',
    action: MediaAction.setRating,
  );

  MediaControl? ratingToControl(int rating) {
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
        return null;
    }
  }
}

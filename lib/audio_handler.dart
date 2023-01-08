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
  MediaItem? mediaItem;
}

SingletonConfig getConfig() {
  return GetIt.I<SingletonConfig>();
}

AudioHandler getAudioHandler() {
  return GetIt.I<AudioHandler>();
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

AudioPlayer initAudioPlayer() {
  var player = AudioPlayer();
  GetIt.I.registerSingleton(player);
  return player;
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = initAudioPlayer();
  final _config = getConfig();

  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  void setMediaItem(MediaItem newMediaItem) async {
    mediaItem.add(newMediaItem);
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    ratingStyle.add(RatingStyle.thumbUpDown);

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
      playbackState.add(playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          like,
          dislike
        ],
        systemActions: const {MediaAction.seek, MediaAction.setRating},
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
      ));
      ratingStyle.add(RatingStyle.thumbUpDown);
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
    action: MediaAction.setRating,
  );

  static MediaControl dislike = const MediaControl(
    androidIcon: 'drawable/thumbs_down',
    label: 'Dislike',
    action: MediaAction.setRating,
  );
}

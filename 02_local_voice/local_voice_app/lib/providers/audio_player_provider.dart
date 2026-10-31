import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  String? _currentAudioUrl;
  bool _isLoading = false;

  AudioPlayerProvider() {
    _initListeners();
  }

  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;
  double get playbackSpeed => _playbackSpeed;
  String? get currentAudioUrl => _currentAudioUrl;
  bool get isLoading => _isLoading;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;

  void _initListeners() {
    _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _isLoading = false;
      notifyListeners();
    });

    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _position = Duration.zero;
      _playerState = PlayerState.completed;
      notifyListeners();
    });
  }

  Future<void> play(String url) async {
    try {
      if (_currentAudioUrl == url && _playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }

      _isLoading = true;
      _currentAudioUrl = url;
      notifyListeners();

      await _player.stop();
      await _player.setPlaybackRate(_playbackSpeed);

      if (url.startsWith('http://') || url.startsWith('https://')) {
        await _player.play(UrlSource(url));
      } else {
        await _player.play(DeviceFileSource(url));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isLoading = false;
      _playerState = PlayerState.stopped;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration target) async {
    await _player.seek(target);
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setPlaybackRate(speed);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

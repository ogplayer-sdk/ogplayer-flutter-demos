import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../event_log.dart';
import '../theme.dart';

/// Picture-in-picture: no button anywhere — the developer decides. With
/// `pipEnabled`, leaving the app (Home / recents) while playing
/// auto-enters PiP, and closing the PiP window pauses playback. On
/// Android the whole activity IS the little window, so this screen hides
/// its own panel while `onPipChanged` reports active; on iOS the system
/// floats a separate video window and the app UI is simply backgrounded.
class PipDemo extends StatefulWidget {
  const PipDemo({super.key});

  @override
  State<PipDemo> createState() => _PipDemoState();
}

class _PipDemoState extends State<PipDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;
  bool _inPip = false;
  bool _autoEnter = true;

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chromeVisible = !_isFullscreen && !_inPip;
    final windowSize = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: InkColors.background,
      // Native parity: the Android demos have no top bar at all; the iOS
      // demos show the navigation bar outside fullscreen.
      appBar: (chromeVisible && !Platform.isAndroid)
          ? AppBar(
              backgroundColor: InkColors.background,
              title: const Text(
                'Picture-in-picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: SafeArea(
        top: chromeVisible,
        bottom: chromeVisible,
        child: Column(
          children: [
            AspectRatio(
              // In PiP the window matches the VIDEO's aspect (this rendition
              // is 1152x480, ~2.4:1), so track the window itself there; the
              // widget type stays AspectRatio so the platform view survives.
              aspectRatio: _inPip && windowSize.height > 0
                  ? windowSize.width / windowSize.height
                  : 16 / 9,
              child: OGPlayerView(
                source: const OGMediaItem(
                  url: 'https://media.ogplayer.tv/tos/master.m3u8',
                  streamType: OGStreamType.vod,
                  title: 'Tears of Steel',
                ),
                autoplay: true,
                autoFullscreenOnRotate: true,
                pipEnabled: true,
                autoEnterPipOnBackground: _autoEnter,
                onPipChanged: (isActive) {
                  _log.add('onPipChanged: $isActive');
                  setState(() => _inPip = isActive);
                },
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onStateChanged: (state) =>
                    _log.add('onStateChanged: ${state.name}'),
                onPlay: () => _log.add('onPlay'),
                onPause: () => _log.add('onPause'),
                onResume: () => _log.add('onResume'),
                onSeekCompleted: (positionMs) =>
                    _log.add('onSeekCompleted: ${positionMs ~/ 1000}s'),
                onPlaybackCompleted: () => _log.add('onPlaybackCompleted'),
                onError: (error) => _log.add('onError: $error'),
                onAnalyticsEvent: (event) =>
                    _log.add('analytics: ${event.description ?? event}'),
              ),
            ),
            if (chromeVisible) ...[
              Row(
                children: [
                  Checkbox(
                    value: _autoEnter,
                    activeColor: InkColors.accent,
                    checkColor: InkColors.onAccent,
                    onChanged: (v) => setState(() => _autoEnter = v == true),
                  ),
                  const Expanded(
                    child: Text(
                      'Auto-enter PiP when leaving the app',
                      style: TextStyle(color: InkColors.title, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'Press Home while playing — PiP enters automatically. The '
                  'chrome is stripped in the little window, its play/pause '
                  'remote action drives the player, and closing it (✕) pauses '
                  'playback — all logged below.',
                  style: TextStyle(color: InkColors.description, fontSize: 12),
                ),
              ),
              Expanded(child: EventLogView(_log)),
            ],
          ],
        ),
      ),
    );
  }
}

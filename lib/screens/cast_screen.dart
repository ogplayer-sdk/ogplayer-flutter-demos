import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../event_log.dart';
import '../theme.dart';

/// Chromecast (Android) / AirPlay (iOS). `castEnabled` attaches the SDK's
/// cast connector on Android — the cast button appears top-right in the
/// player controls and opens the device picker; a real cast device is
/// needed for the actual hand-off. On iOS the same flag surfaces the
/// system AirPlay route button (`showCastButton` maps to it). The Android
/// side also needs the Cast options provider meta-data in the app
/// manifest (see plugin README — the example declares it).
class CastDemo extends StatefulWidget {
  const CastDemo({super.key});

  @override
  State<CastDemo> createState() => _CastDemoState();
}

class _CastDemoState extends State<CastDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;
  bool _showCastButton = true;

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final buttonLabel = isIOS ? 'SDK AirPlay button' : 'SDK cast button';
    final explainer = isIOS
        ? 'Tap the player: the AirPlay button sits top-right in the '
              'controls and opens the system route picker (an AirPlay '
              'target on the network is needed for the hand-off). Toggle '
              'the switch to hide it — apps can bring their own '
              'AVRoutePickerView instead.'
        : 'Tap the player: the cast button sits top-right in the controls '
              'and opens the device picker (a real cast device is needed '
              'for the hand-off). Toggle the switch to hide the SDK\'s '
              'button — the connector keeps working, so an app can bring '
              'its own cast UI instead.';
    return Scaffold(
      backgroundColor: InkColors.background,
      // Native parity: the Android demos have no top bar at all; the iOS
      // demos show the navigation bar outside fullscreen.
      appBar: (_isFullscreen || Platform.isAndroid)
          ? null
          : AppBar(
              backgroundColor: InkColors.background,
              title: const Text(
                'Chromecast',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: OGPlayerView(
                source: const OGMediaItem(
                  url: 'https://media.ogplayer.tv/tos/master.m3u8',
                  streamType: OGStreamType.vod,
                  title: 'Cast demo',
                  posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
                ),
                castEnabled: true,
                autoFullscreenOnRotate: true,
                uiConfig: OGUIConfig(showCastButton: _showCastButton),
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
            if (!_isFullscreen) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: InkColors.title,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Switch(
                      value: _showCastButton,
                      activeThumbColor: InkColors.onAccent,
                      activeTrackColor: InkColors.accent,
                      onChanged: (v) => setState(() => _showCastButton = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  explainer,
                  style: const TextStyle(
                    color: InkColors.description,
                    fontSize: 12,
                  ),
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

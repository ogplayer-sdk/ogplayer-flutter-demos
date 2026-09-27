import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../event_log.dart';
import '../theme.dart';

/// Live showcase, both flavors: LIVE (locked to the edge, no seeking) and
/// LIVE_DVR (seekable window). Scrub behind the DVR edge and watch
/// onLiveEdgeChanged flip in the log; tap the LIVE chip in the chrome or
/// "To live edge" (seekToLiveEdge()) to jump back. Switching flavor swaps
/// the source prop → native reload.
class LiveDemo extends StatefulWidget {
  const LiveDemo({super.key});

  @override
  State<LiveDemo> createState() => _LiveDemoState();
}

const _liveUrl =
    'https://demo.unified-streaming.com/k8s/live/stable/live.isml/.m3u8';

// Shown under both flavors: one audio language, no subtitles, no rate changes
// at the live edge.
const _hiddenButtonsNote =
    'One audio language and no subtitles: the subtitle and audio buttons are '
    'hidden (showSubtitleButton / showAudioTrackButton = false); speed goes '
    'too — no rate changes at the live edge (showSpeedButton = false).';

class _LiveDemoState extends State<LiveDemo> {
  final _log = EventLogState();
  OGPlayerViewController? _controller;
  bool _isFullscreen = false;
  bool _dvr = false;

  // onProgress fires several times a second — log at most once per
  // position-second, resetting on reload.
  int _lastLoggedSecond = -1;

  @override
  void initState() {
    super.initState();
    _log.add('— loading LIVE (locked to edge) —');
  }

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  void _selectFlavor(bool dvr) {
    if (dvr == _dvr) return;
    setState(() {
      _dvr = dvr;
      _lastLoggedSecond = -1;
    });
    _log.add(
      dvr
          ? '— loading LIVE_DVR (seekable window) —'
          : '— loading LIVE (locked to edge) —',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InkColors.background,
      // Native parity: the Android demos have no top bar at all; the iOS
      // demos show the navigation bar outside fullscreen.
      appBar: (_isFullscreen || Platform.isAndroid)
          ? null
          : AppBar(
              backgroundColor: InkColors.background,
              title: const Text(
                'Live & DVR',
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
                source: OGMediaItem(
                  url: _liveUrl,
                  streamType: _dvr ? OGStreamType.liveDvr : OGStreamType.live,
                  title: _dvr ? 'Live DVR demo' : 'Live demo',
                ),
                // AirPlay/cast isn't relevant to this scenario (mirrors the
                // native iOS demo hiding the AirPlay button). One audio
                // language, no subtitles: the subtitle and audio menus would
                // be empty. No rate changes at the live edge, so speed goes
                // too. Quality stays — four variants.
                uiConfig: const OGUIConfig(
                  showCastButton: false,
                  showSubtitleButton: false,
                  showAudioTrackButton: false,
                  showSpeedButton: false,
                ),
                autoplay: true,
                autoFullscreenOnRotate: true,
                onViewCreated: (controller) => _controller = controller,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onStateChanged: (state) =>
                    _log.add('onStateChanged: ${state.name}'),
                onLiveEdgeChanged: (atLiveEdge) =>
                    _log.add('onLiveEdgeChanged: atLiveEdge=$atLiveEdge'),
                onSeekCompleted: (positionMs) =>
                    _log.add('onSeekCompleted: ${positionMs}ms'),
                onProgress: (progress) {
                  final second = progress.positionMs ~/ 1000;
                  if (second == _lastLoggedSecond) return;
                  _lastLoggedSecond = second;
                  _log.add(
                    'onProgress: ${progress.positionMs}ms '
                    '/ ${progress.durationMs}ms',
                  );
                },
                onError: (error) => _log.add('onError: $error'),
              ),
            ),
            if (!_isFullscreen) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ScenarioChips(
                      labels: const [
                        'Live (locked to edge)',
                        'Live DVR (seekable)',
                      ],
                      selected: _dvr ? 1 : 0,
                      onSelected: (index) => _selectFlavor(index == 1),
                    ),
                  ),
                  if (_dvr)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 8),
                      child: OutlinedButton(
                        // The imperative twin of tapping the LIVE chip in the
                        // chrome — hosts can jump back programmatically.
                        onPressed: () => _controller?.seekToLiveEdge(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InkColors.accent,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'To live edge',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  _dvr
                      ? 'LIVE_DVR — scrub behind the edge, then tap the LIVE '
                            'chip or "To live edge" (seekToLiveEdge()) to jump '
                            'back. The label reads LIVE at the edge, else a '
                            '−offset; the thumb creeps toward live as you '
                            'watch behind it. $_hiddenButtonsNote'
                      : 'LIVE — no seeking: no progress bar, the chip stays '
                            'at the edge. $_hiddenButtonsNote',
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

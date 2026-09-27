import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../event_log.dart';
import '../theme.dart';

/// Public LL-HLS test stream: ~1 s fMP4 parts (EXT-X-PART), blocking playlist
/// reload and a PART-HOLD-BACK in EXT-X-SERVER-CONTROL, with a UTC clock
/// burned into the picture.
const _lowLatencyUrl =
    'https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8';

/// Low-latency HLS: the same item as any live stream — no flag, no tuning.
/// The test stream keeps only ~20 s of history, so it plays as plain LIVE:
/// the LIVE chip, no rewind bar, no seek buttons.
///
/// The readout, twice a second: how far the playhead's program date-time
/// (EXT-X-PROGRAM-DATE-TIME, via `getLiveInfo()`'s `playheadWallClockMs`)
/// runs behind this device's clock — one number, the delay a viewer actually
/// experiences.
class LowLatencyLiveDemo extends StatefulWidget {
  const LowLatencyLiveDemo({super.key});

  @override
  State<LowLatencyLiveDemo> createState() => _LowLatencyLiveDemoState();
}

class _LowLatencyLiveDemoState extends State<LowLatencyLiveDemo> {
  final _log = EventLogState();
  OGPlayerViewController? _controller;
  bool _isFullscreen = false;
  int? _behindMs;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _log.add('— loading LIVE low-latency HLS —');
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final wall = (await _controller?.getLiveInfo())?.playheadWallClockMs;
      if (!mounted) return;
      setState(
        () => _behindMs = wall == null
            ? null
            : max(0, DateTime.now().millisecondsSinceEpoch - wall),
      );
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _log.dispose();
    super.dispose();
  }

  static const _note =
      'Nothing to configure — the same item as any live stream. The engine '
      'holds the playlist’s PART-HOLD-BACK and plays a few seconds behind '
      'real time; part of that delay is the stream’s own, before it reaches '
      'the player. This test stream keeps only about 20 s of history, so it '
      'plays as plain live: no rewind bar. Pause, and “To live edge” '
      '(seekToLiveEdge()) brings the delay back down. The clock painted into '
      'the picture comes from the stream’s encoder and can differ from the '
      'stream’s time stamps by a second or two.';

  @override
  Widget build(BuildContext context) {
    final behind = _behindMs;
    return Scaffold(
      backgroundColor: InkColors.background,
      // Native parity: the Android demos have no top bar at all; the iOS
      // demos show the navigation bar outside fullscreen.
      appBar: (_isFullscreen || Platform.isAndroid)
          ? null
          : AppBar(
              backgroundColor: InkColors.background,
              title: const Text(
                'Low-latency live',
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
                // Plain LIVE: a ~20 s window is no DVR — the chrome shows the
                // LIVE chip and no rewind bar.
                source: const OGMediaItem(
                  url: _lowLatencyUrl,
                  streamType: OGStreamType.live,
                  title: 'Low-latency live',
                ),
                // One audio rendition and no subtitles: the buttons that would
                // open an empty menu are hidden, speed goes too (no rate
                // changes at the live edge), cast is not part of this
                // scenario. The quality ladder stays.
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
                onAnalyticsEvent: (event) =>
                    _log.add('analytics: ${event.description ?? event}'),
                onError: (error) => _log.add('onError: $error'),
              ),
            ),
            if (!_isFullscreen) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Behind real time: '
                    '${behind != null ? '${(behind / 1000).toStringAsFixed(1)} s' : '—'}',
                    style: const TextStyle(
                      color: InkColors.title,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      fontFamilyFallback: ['Menlo', 'Courier'],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    // The imperative twin of tapping the LIVE chip in the
                    // chrome.
                    onPressed: () {
                      _log.add('— seekToLiveEdge() —');
                      _controller?.seekToLiveEdge();
                    },
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: const Text(
                  _note,
                  style: TextStyle(color: InkColors.description, fontSize: 12),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Content: Big Buck Bunny — (CC) Blender Foundation, via '
                    'Mux’s public low-latency test stream',
                    style: TextStyle(
                      color: InkColors.groupHeader,
                      fontSize: 11,
                    ),
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

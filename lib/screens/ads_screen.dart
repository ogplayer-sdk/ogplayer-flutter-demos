import 'dart:io' show Platform;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../event_log.dart';
import '../theme.dart';

/// Client-side Google IMA ads. Pick a scenario (skippable preroll, or a VMAP
/// pre/mid/post pod schedule); the player reloads the content with the ad tag
/// and streams every ad callback into the green event log. IMA renders its own
/// skip / "Learn More" UI; the SDK draws the yellow bar, AD chip and countdown.
class AdsDemo extends StatefulWidget {
  const AdsDemo({super.key});

  @override
  State<AdsDemo> createState() => _AdsDemoState();
}

// Google's public IMA sample tags — a VAST single ad plus VMAP ad-rule
// scenarios that differ only by cust_params sample_ar. NOTE: Google throttles
// these tags per-IP on heavy same-day use (empty breaks, not an SDK bug).
const _vmapBase =
    'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/'
    'vmap_ad_samples&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&ad_rule=1'
    '&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496'
    '&vid=short_onecue&correlator=';

const _scenarios = <(String, String)>[
  (
    'Skippable preroll',
    'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/'
        'single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1'
        '&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=',
  ),
  ('Pre + mid + post', '$_vmapBase&cust_params=sample_ar%3Dpremidpost'),
  ('Mid-roll pod (3 ads)', '$_vmapBase&cust_params=sample_ar%3Dpremidpostpod'),
  ('Long pod (5 ads)', '$_vmapBase&cust_params=sample_ar%3Dpremidpostlongpod'),
  (
    'Broken tag (error)',
    'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/'
        'does_not_exist&sz=640x480&gdfp_req=1&output=vast&env=vp&impl=s'
        '&correlator=',
  ),
];

// Short (~60s) clip so the VMAP sample's mid/post cue points land at
// sensible positions on the scrubber.
const _contentUrl = 'https://media.ogplayer.tv/tos-clip-60s.mp4';

// A progressive MP4: one audio track, no text tracks, a single quality —
// the buttons that would open empty menus are hidden explicitly.
const _uiConfig = OGUIConfig(
  showSubtitleButton: false,
  showAudioTrackButton: false,
  showQualityButton: false,
);

class _AdsDemoState extends State<AdsDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;
  int _scenario = 0;

  @override
  void initState() {
    super.initState();
    _log.add('— loading ${_scenarios[_scenario].$1} —');
  }

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  // Scenario switch = source-prop swap (new ads config) → native reload.
  OGMediaItem get _item => OGMediaItem(
    url: _contentUrl,
    streamType: OGStreamType.vod,
    title: 'Ads demo — ${_scenarios[_scenario].$1}',
    ads: AdsConfig(adTagUrl: _scenarios[_scenario].$2),
  );

  void _selectScenario(int index) {
    if (index == _scenario) return;
    setState(() => _scenario = index);
    _log.add('— loading ${_scenarios[index].$1} —');
  }

  /// Native-style log lines from the payload both hosts emit
  /// (breakType/totalAds on break events; position/totalAds/durationMs on
  /// per-ad events).
  void _logAdEvent(OGAdEvent event) {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(event.json) as Map<String, dynamic>;
    } catch (_) {
      _log.add('ad ${event.type}');
      return;
    }
    switch (event.type) {
      case 'breakStarted':
        _log.add(
          'onAdBreakStarted: ${payload['breakType']}, '
          '${payload['totalAds']} ads',
        );
      case 'breakCompleted':
        _log.add('onAdBreakCompleted: ${payload['breakType']}');
      default:
        final pod = payload['totalAds'] != null
            ? ' ${payload['position']}/${payload['totalAds']}'
            : '';
        final duration = payload['durationMs'] != null
            ? ', ${payload['durationMs']}ms'
            : '';
        _log.add('onAd${_capitalize(event.type)}: ad$pod$duration');
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
                'Ads',
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
                source: _item,
                uiConfig: _uiConfig,
                autoplay: true,
                adsEnabled: true,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onAdEvent: _logAdEvent,
                onStateChanged: (state) => _log.add('onStateChanged: $state'),
                onPlay: () => _log.add('onPlay'),
                onPause: () => _log.add('onPause'),
                onPlaybackCompleted: () => _log.add('onPlaybackCompleted'),
                onError: (error) => _log.add('onError: $error'),
              ),
            ),
            if (!_isFullscreen) ...[
              ScenarioChips(
                labels: [for (final (label, _) in _scenarios) label],
                selected: _scenario,
                onSelected: _selectScenario,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'IMA ad scenarios — IMA renders its own skip and '
                  'clickthrough UI; the SDK draws the yellow bar, AD chip '
                  'and countdown. Ad callbacks stream below. Progressive '
                  'MP4 content: the subtitle, audio and quality buttons are '
                  'hidden (showSubtitleButton / showAudioTrackButton / '
                  'showQualityButton = false).',
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

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../event_log.dart';
import '../theme.dart';

/// Content-rating icons (NICAM/Kijkwijzer style): per-item ratings via
/// OGMediaItem.contentRatings, shown at content start (after ads), fixed
/// top-right inline with the Cast button (the Kijkwijzer convention — not
/// repositionable). Defaults are SDK art. The native SDKs also take
/// host-supplied official pictograms (ContentRating.Custom); the Flutter
/// wrapper's ContentRating carries age + descriptors only, so the natives'
/// "Custom badge" chip is not ported.
class NicamDemo extends StatefulWidget {
  const NicamDemo({super.key});

  @override
  State<NicamDemo> createState() => _NicamDemoState();
}

// Google IMA skippable-preroll sample tag — proves the icons wait for the ad:
// with a preroll, ratings show only when CONTENT starts.
const _prerollTag =
    'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/'
    'single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1'
    '&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=';

const _ages = <(ContentRatingAge, String)>[
  (ContentRatingAge.all, 'AL'),
  (ContentRatingAge.six, '6'),
  (ContentRatingAge.nine, '9'),
  (ContentRatingAge.twelve, '12'),
  (ContentRatingAge.fourteen, '14'),
  (ContentRatingAge.sixteen, '16'),
  (ContentRatingAge.eighteen, '18'),
];

// (wire name, chip label) — wire names as both native bridges accept them.
const _descriptors = <(String, String)>[
  ('VIOLENCE', 'Violence'),
  ('FEAR', 'Fear'),
  ('SEX', 'Sex'),
  ('DISCRIMINATION', 'Discrim.'),
  ('DRUGS_ALCOHOL', 'Drugs'),
  ('COARSE_LANGUAGE', 'Language'),
];

class _NicamDemoState extends State<NicamDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;
  ContentRatingAge _age = ContentRatingAge.sixteen;
  Set<String> _selected = {'VIOLENCE', 'FEAR'};
  bool _withPreroll = false;

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  // Any rating/preroll change = source-prop swap → native reload, so the
  // icons re-show at the next content start.
  OGMediaItem get _item => OGMediaItem(
    url: 'https://media.ogplayer.tv/tos/master.m3u8',
    streamType: OGStreamType.vod,
    title: 'NICAM demo',
    contentRatings: [
      ContentRating(
        age: _age,
        descriptors: [
          for (final (wire, _) in _descriptors)
            if (_selected.contains(wire)) wire,
        ],
      ),
    ],
    ads: _withPreroll ? const AdsConfig(adTagUrl: _prerollTag) : null,
  );

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
                'Content ratings',
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
                autoplay: true,
                adsEnabled: true,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onAdEvent: (event) => _log.add('ad: ${event.type}'),
                onStateChanged: (state) => _log.add('onStateChanged: $state'),
                onPlay: () => _log.add('onPlay'),
                onPause: () => _log.add('onPause'),
                onPlaybackCompleted: () => _log.add('onPlaybackCompleted'),
                onError: (error) => _log.add('onError: $error'),
              ),
            ),
            if (!_isFullscreen) ...[
              _groupHeader('AGE'),
              ScenarioChips(
                labels: [for (final (_, label) in _ages) label],
                selected: _ages.indexWhere((a) => a.$1 == _age),
                onSelected: (index) => setState(() => _age = _ages[index].$1),
              ),
              _groupHeader('DESCRIPTORS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final (wire, label) in _descriptors)
                      FilterChip(
                        selected: _selected.contains(wire),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 12),
                        label: Text(label),
                        onSelected: (_) => setState(() {
                          final next = {..._selected};
                          next.contains(wire)
                              ? next.remove(wire)
                              : next.add(wire);
                          _selected = next;
                        }),
                      ),
                    FilterChip(
                      selected: _withPreroll,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      label: const Text('With preroll'),
                      onSelected: (_) =>
                          setState(() => _withPreroll = !_withPreroll),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Icons show at content start (after ads) for 5s, top-right '
                  'inline with the Cast button — the Kijkwijzer convention. '
                  'Defaults are SDK art; licensed hosts supply official NICAM '
                  'pictograms via the native SDKs.',
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

  Widget _groupHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: InkColors.groupHeader,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    ),
  );
}

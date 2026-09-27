import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../event_log.dart';
import '../theme.dart';

/// Custom action icons: up to 8 host-supplied, icon-only buttons rendered
/// inline in the top-end control row, left of where the cast/AirPlay button
/// sits. They are part of the chrome — they show/hide with the controls —
/// while watermarks (overlay slots) are a separate layer below that line.
/// Every tap lands in `onCustomAction` (logged below). Toggle icons one by
/// one to judge spacing; add the watermark + NICAM row to see all three
/// layers. Icon names resolve against APP resources: Android drawables in
/// example/android res, iOS images in the Runner asset catalog.
class CustomActionsDemo extends StatefulWidget {
  const CustomActionsDemo({super.key});

  @override
  State<CustomActionsDemo> createState() => _CustomActionsDemoState();
}

/// Native icon-resource name + the matching Material glyph for the checkbox
/// row (so it's obvious which glyph each checkbox adds).
const _demoIcons = <(String, IconData)>[
  ('og_demo_action_share', Icons.share_outlined),
  ('og_demo_action_favorite', Icons.favorite_outline),
  ('og_demo_action_info', Icons.info_outline),
  ('og_demo_action_star', Icons.star_outline),
  ('og_demo_action_search', Icons.search),
  ('og_demo_action_chat', Icons.chat_bubble_outline),
  ('og_demo_action_download', Icons.download_outlined),
  ('og_demo_action_clock', Icons.access_time),
];

class _CustomActionsDemoState extends State<CustomActionsDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;
  Set<int> _enabledIcons = {0, 1};
  bool _watermark = false;
  bool _nicam = false;

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  // Ratings render once at content start, so toggling NICAM swaps the source
  // (contentRatings change → the wrapper reloads the item).
  OGMediaItem get _item => OGMediaItem(
    url: 'https://media.ogplayer.tv/tos/master.m3u8',
    streamType: OGStreamType.vod,
    contentRatings: _nicam
        ? const [
            ContentRating(age: ContentRatingAge.sixteen, descriptors: ['FEAR']),
          ]
        : null,
  );

  OGUIConfig get _uiConfig => OGUIConfig(
    customActions: [
      for (final index in _enabledIcons.toList()..sort())
        CustomActionConfig(
          iconName: _demoIcons[index].$1,
          accessibilityLabel: 'Icon ${index + 1}',
        ),
    ],
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
                'Custom action icons',
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
                overlays: _watermark
                    ? const [
                        OverlayConfig(
                          slot: OverlaySlot.topEnd,
                          text: 'WATERMARK',
                          textSize: 12,
                        ),
                      ]
                    : null,
                autoplay: true,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onCustomAction: (index) {
                  final ordered = _enabledIcons.toList()..sort();
                  if (index < ordered.length) {
                    _log.add('custom icon${ordered[index] + 1} tap callback');
                  }
                },
                onStateChanged: (state) =>
                    _log.add('onStateChanged: ${state.name}'),
                onPlay: () => _log.add('onPlay'),
                onPause: () => _log.add('onPause'),
                onResume: () => _log.add('onResume'),
                onSeekCompleted: (positionMs) =>
                    _log.add('onSeekCompleted: ${positionMs ~/ 1000}s'),
                onPlaybackCompleted: () => _log.add('onPlaybackCompleted'),
                onLiveEdgeChanged: (atLiveEdge) =>
                    _log.add('onLiveEdgeChanged: $atLiveEdge'),
                onError: (error) => _log.add('onError: $error'),
                onAnalyticsEvent: (event) =>
                    _log.add('analytics: ${event.description ?? event}'),
              ),
            ),
            if (!_isFullscreen) ...[
              // Icons 1-8, individually toggleable (max 8 = the SDK cap).
              for (final range in [(0, 4), (4, 8)])
                Row(
                  children: [
                    for (var i = range.$1; i < range.$2; i++) ...[
                      Checkbox(
                        value: _enabledIcons.contains(i),
                        activeColor: InkColors.accent,
                        checkColor: InkColors.onAccent,
                        onChanged: (checked) => setState(() {
                          final next = {..._enabledIcons};
                          if (checked == true) {
                            next.add(i);
                          } else {
                            next.remove(i);
                          }
                          _enabledIcons = next;
                        }),
                      ),
                      Icon(_demoIcons[i].$2, color: InkColors.title, size: 24),
                    ],
                  ],
                ),
              Row(
                children: [
                  Checkbox(
                    value: _watermark,
                    activeColor: InkColors.accent,
                    checkColor: InkColors.onAccent,
                    onChanged: (v) => setState(() => _watermark = v == true),
                  ),
                  const Text(
                    'Watermark',
                    style: TextStyle(color: InkColors.title, fontSize: 13),
                  ),
                  Checkbox(
                    value: _nicam,
                    activeColor: InkColors.accent,
                    checkColor: InkColors.onAccent,
                    onChanged: (v) => setState(() => _nicam = v == true),
                  ),
                  const Text(
                    'NICAM (reloads)',
                    style: TextStyle(color: InkColors.title, fontSize: 13),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  'White icons sit inline left of the '
                  '${Platform.isIOS ? 'AirPlay' : 'cast'} position and hide '
                  'with the controls; each tap fires onCustomAction (logged '
                  'below). Watermark is a separate overlay layer below the '
                  'control line; NICAM icons show at content start.',
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

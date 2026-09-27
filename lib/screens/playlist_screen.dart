import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../event_log.dart';
import '../theme.dart';

/// Playlist & "Up next": three short clips queue and auto-advance; a
/// countdown card appears in the lead window before each item ends (tap it
/// to skip immediately). Every knob has a mode chip: the lead time, the
/// card's text template, its colors and font — or no card at all (silent
/// advance). The card is deliberately config-only: no custom-view slot.
/// Config chips apply live (uiConfig is a widget prop); only "With ads"
/// changes the playlist itself and reloads the queue.
class PlaylistDemo extends StatefulWidget {
  const PlaylistDemo({super.key});

  @override
  State<PlaylistDemo> createState() => _PlaylistDemoState();
}

// Google's public IMA sample tags — a skippable preroll (VAST) and a
// postroll-only ad rule (VMAP).
const _skippablePreroll =
    'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/'
    'single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1'
    '&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=';
const _postrollOnly =
    'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/'
    'vmap_ad_samples&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&ad_rule=1'
    '&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496'
    '&vid=short_onecue&cust_params=sample_ar%3Dpostonly&correlator=';

const _clips = <(String, String, String?)>[
  ('w169-01', 'The old church', _skippablePreroll),
  ('w169-02', 'Crossing the bridge', _postrollOnly),
  ('w169-03', 'The machine waits', null),
];

/// Ads are PER ITEM: with [withAds], clip 1 opens with a skippable preroll,
/// clip 2 ends with a postroll (played BEFORE the queue advances), clip 3
/// stays ad-free.
List<OGMediaItem> _playlistItems({required bool withAds}) => [
  for (final (file, title, adTag) in _clips)
    OGMediaItem(
      url: 'https://media.ogplayer.tv/shorts/v3/$file.mp4',
      streamType: OGStreamType.vod,
      title: title,
      posterUrl: 'https://media.ogplayer.tv/shorts/v3/$file.jpg',
      ads: withAds && adTag != null ? AdsConfig(adTagUrl: adTag) : null,
    ),
];

class _PlaylistDemoState extends State<PlaylistDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;

  // 0=default, 1=short lead, 2=custom text, 3=branded, 4=hidden, 5=with ads
  int _mode = 0;

  @override
  void initState() {
    super.initState();
    _log.add('— loading playlist (3 clips, 14s each) —');
  }

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  /// Progressive MP4 clips: one audio track, no text tracks, no ladder —
  /// buttons that would open an empty menu are hidden in every mode.
  OGUIConfig get _uiConfig => switch (_mode) {
    1 => const OGUIConfig(
      showSubtitleButton: false,
      showAudioTrackButton: false,
      showQualityButton: false,
      upNextLeadSeconds: 5,
    ),
    2 => const OGUIConfig(
      showSubtitleButton: false,
      showAudioTrackButton: false,
      showQualityButton: false,
      upNextText: '{title} starts in {seconds}s…',
    ),
    3 => const OGUIConfig(
      showSubtitleButton: false,
      showAudioTrackButton: false,
      showQualityButton: false,
      upNextText: 'Up next · {title} · {seconds}',
      upNextBackgroundColor: '#E6F6C445',
      upNextTextColor: '#FF131313',
      upNextTextSize: 13,
      upNextFontFamily: 'serif',
    ),
    4 => const OGUIConfig(
      showSubtitleButton: false,
      showAudioTrackButton: false,
      showQualityButton: false,
      showUpNext: false,
    ),
    _ => const OGUIConfig(
      showSubtitleButton: false,
      showAudioTrackButton: false,
      showQualityButton: false,
    ),
  };

  String get _explainer => switch (_mode) {
    1 =>
      'upNextLeadSeconds: 5 — the card appears 5 seconds before the '
          'end instead of the default 10.',
    2 =>
      "upNextText: '{title} starts in {seconds}s…' — your copy, any "
          'language; {seconds} and {title} are substituted.',
    3 =>
      'upNextBackgroundColor / TextColor / TextSize / FontFamily — '
          'brand the card: accent background, serif font, dark text.',
    4 =>
      'showUpNext: false — no card at all; the playlist still '
          'auto-advances silently.',
    5 =>
      'Ads are per item (ads: on each OGMediaItem): clip 1 opens with '
          'a skippable preroll, clip 2 ends with a postroll that plays '
          'before the queue advances, clip 3 is ad-free.',
    _ =>
      'Three 14-second clips auto-advance; the "Up next" card counts '
          'down during the last 10 seconds — tap it to jump '
          'immediately. Config chips apply live; "With ads" reloads the '
          'queue.',
  };

  void _selectMode(int mode) {
    if (mode == _mode) return;
    // Modes 0–4 only touch uiConfig (applies live, playback continues);
    // entering/leaving "With ads" swaps the playlist prop → native reload.
    final reloads = (mode == 5) != (_mode == 5);
    setState(() => _mode = mode);
    if (reloads) {
      _log.add(
        mode == 5
            ? '— loading playlist with per-item IMA tags —'
            : '— loading playlist (3 clips, 14s each) —',
      );
    }
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
                'Playlist & up next',
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
                playlist: _playlistItems(withAds: _mode == 5),
                uiConfig: _uiConfig,
                autoplay: true,
                adsEnabled: true,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onPlaylistItemChanged: (index, title) =>
                    _log.add('onPlaylistItemChanged: #$index · $title'),
                onPlaylistItemSkipped: (fromIndex, toIndex) =>
                    _log.add('onPlaylistItemSkipped: #$fromIndex → #$toIndex'),
                onPlaybackCompleted: () => _log.add('onPlaybackCompleted'),
                onError: (error) => _log.add('onError: $error'),
                onAdEvent: (event) => _log.add('ad: ${event.type}'),
              ),
            ),
            if (!_isFullscreen) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ScenarioChips(
                      labels: const [
                        'Default',
                        'Lead 5s',
                        'Custom text',
                        'Branded style',
                        'Hidden',
                        'With ads',
                      ],
                      selected: _mode,
                      onSelected: _selectMode,
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
                  '$_explainer The clips are progressive MP4s with one audio '
                  'track, no subtitles and no ladder, so the subtitle, audio '
                  'and quality buttons are hidden.',
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

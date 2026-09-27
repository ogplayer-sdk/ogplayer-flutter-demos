import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../event_log.dart';
import '../theme.dart';

/// Subtitles & audio showcase — mirrors the native Tracks demos.
///
/// Content: "Tears of Steel" ((CC) Blender Foundation) throughout. The
/// "Embedded" case streams the variant with five subtitle languages muxed
/// into the HLS manifest (the demo auto-selects the first so they're
/// visible); the sideloaded case attaches the movie's real dialog subs —
/// five VTT files — and "Positioned VTT" exercises every cue setting
/// (line/position/align/size). The native demos bundle the VTTs as app
/// assets; here they're the same files served from demo.ogplayer.tv, which
/// both platform hosts accept as plain https SubtitleSource URLs.
///
/// Font size drives `subtitleTextScale`, the caption font drives
/// `SubtitleStyle.fontFamily` (Georgia on iOS, serif on Android — the
/// obviously-different "custom" font; a real app passes its brand font),
/// and the volume chips drive `volumeControlMode`.
class TracksDemo extends StatefulWidget {
  const TracksDemo({super.key});

  @override
  State<TracksDemo> createState() => _TracksDemoState();
}

const _stream = 'https://media.ogplayer.tv/tos/master.m3u8';
const _poster = 'https://media.ogplayer.tv/posters/tos-mech.jpg';
const _subsBase = 'https://demo.ogplayer.tv/subs';

/// The movie's own subtitles (language code, menu label) — same five
/// languages the native demos bundle.
const _dialogSubs = [
  ('en', 'English'),
  ('de', 'Deutsch'),
  ('fr', 'Français'),
  ('es', 'Español'),
  ('ru', 'Русский'),
];

/// Subtitle text-size presets → `subtitleTextScale`.
const _sizeOptions = [
  ('Small', 0.8),
  ('Default', 1.0),
  ('Large', 1.4),
  ('X-Large', 1.8),
];

class _TracksDemoState extends State<TracksDemo> {
  final _log = EventLogState();
  OGPlayerViewController? _controller;
  bool _isFullscreen = false;
  int _source = 0;
  int _sizeIndex = 1;
  bool _captionSerif = false;
  int _volumeMode = 0;

  // Same four options, same order and short labels as the native demos.
  static const _sourceLabels = [
    'Embedded',
    'Multi-audio',
    'Sideloaded VTT',
    'Positioned VTT',
  ];
  static const _sourceLogLabels = [
    'Embedded (in manifest)',
    'Multi-audio (stereo · 5.1 · M&E)',
    'Sideloaded VTT',
    'Positioned VTT (line/position cues)',
  ];

  late final String _customFontLabel = Platform.isIOS
      ? 'Georgia (custom)'
      : 'Serif (custom)';
  late final String _customFontFamily = Platform.isIOS ? 'Georgia' : 'serif';

  @override
  void initState() {
    super.initState();
    _log.add('— loading ${_sourceLogLabels[_source]} —');
  }

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  void _selectSource(int index) {
    if (index == _source) return;
    setState(() => _source = index);
    _log.add('— loading ${_sourceLogLabels[index]} —');
  }

  OGMediaItem _buildItem() {
    switch (_source) {
      // Mirrors the natives' "Multi-audio" option verbatim, including its
      // asset (the audio-menu showcase).
      case 1:
        return const OGMediaItem(
          url: _stream,
          streamType: OGStreamType.vod,
          title: 'Tears of Steel — three audio tracks',
          posterUrl: _poster,
        );
      case 2:
        return OGMediaItem(
          url: _stream,
          streamType: OGStreamType.vod,
          title: 'Tears of Steel — sideloaded VTT (5 languages)',
          sideloadedSubtitles: [
            for (final (code, label) in _dialogSubs)
              SubtitleSource(
                url: '$_subsBase/tears_of_steel_$code.vtt',
                language: code,
                label: label,
                isDefault: code == 'en',
              ),
          ],
        );
      case 3:
        return const OGMediaItem(
          url: _stream,
          streamType: OGStreamType.vod,
          title: 'Tears of Steel — positioned VTT',
          posterUrl: _poster,
          sideloadedSubtitles: [
            SubtitleSource(
              url: '$_subsBase/test_cue_settings.vtt',
              language: 'en',
              label: 'Cue settings test',
              isDefault: true,
            ),
          ],
        );
      default:
        return const OGMediaItem(
          url: _stream,
          streamType: OGStreamType.vod,
          title: 'Tears of Steel — embedded subtitles (5 languages)',
        );
    }
  }

  void _onTracksChanged(OGTracks tracks) {
    final selectedText = tracks.textTracks
        .where((t) => t.selected)
        .map((t) => t.label)
        .join(', ');
    _log.add(
      'onTracksChanged: ${tracks.textTracks.length} text / '
      '${tracks.audioTracks.length} audio / '
      '${tracks.videoQualities.length} qualities'
      '${selectedText.isEmpty ? '' : ' · CC: $selectedText'}',
    );
    // Embedded subs are off by default — auto-select the first so the
    // "Embedded" source actually shows subtitles. Sideloaded/positioned are
    // already auto-selected by the SDK (isDefault).
    if (_source == 0 &&
        tracks.textTracks.isNotEmpty &&
        !tracks.textTracks.any((t) => t.selected)) {
      _controller?.selectTextTrack(tracks.textTracks.first.id);
    }
  }

  /// The natives' plain `Text(label)` — body text, left-aligned.
  Widget _label(String text, {double topPadding = 0}) => Padding(
    padding: EdgeInsets.only(top: topPadding, bottom: 2),
    child: Text(
      text,
      // Compose's default body text (16sp) in the natives.
      style: const TextStyle(color: InkColors.title, fontSize: 16),
    ),
  );

  /// The natives' full-width `FilterChip(Modifier.fillMaxWidth())`: a 32dp
  /// chip on a 48dp touch row (so stacked chips get the same 16dp gaps),
  /// label left-aligned. Hand-built because Flutter's FilterChip sizes to
  /// its content and centres itself in a wide parent, which is not the
  /// native look.
  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Material(
      color: selected ? InkColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 32,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: selected
                  ? InkColors.onAccent
                  : Colors.white.withValues(alpha: 0.87),
            ),
          ),
        ),
      ),
    ),
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
                'Subtitles & audio',
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
                source: _buildItem(),
                // AirPlay/cast isn't relevant to this scenario (mirrors the
                // native demos hiding the cast/AirPlay button).
                uiConfig: const OGUIConfig(showCastButton: false),
                autoplay: false,
                autoFullscreenOnRotate: true,
                subtitleTextScale: _sizeOptions[_sizeIndex].$2,
                subtitleStyle: SubtitleStyle(
                  fontFamily: _captionSerif ? _customFontFamily : null,
                ),
                volumeControlMode: _volumeMode == 0
                    ? OGVolumeControlMode.device
                    : OGVolumeControlMode.player,
                onViewCreated: (controller) => _controller = controller,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
                onTracksChanged: _onTracksChanged,
                onStateChanged: (state) =>
                    _log.add('onStateChanged: ${state.name}'),
                onPlay: () => _log.add('onPlay'),
                onPause: () => _log.add('onPause'),
                onResume: () => _log.add('onResume'),
                onSeekCompleted: (positionMs) =>
                    _log.add('onSeekCompleted: ${positionMs}ms'),
                onError: (error) => _log.add('onError: $error'),
                onAnalyticsEvent: (event) =>
                    _log.add('analytics: ${event.description ?? event}'),
              ),
            ),
            if (!_isFullscreen)
              // Everything under the player scrolls as one page (the natives
              // keep this block fixed and give the log whatever is left,
              // which on a phone is three lines). The log keeps a readable
              // fixed height and scrolls on its own inside.
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Same block as the native demos: subtitle SOURCE left, font
                    // SIZE right, then caption font and the volume mode — plain
                    // labels, full-width chips, no prose.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Subtitle source'),
                                    for (
                                      var i = 0;
                                      i < _sourceLabels.length;
                                      i++
                                    )
                                      _chip(
                                        _sourceLabels[i],
                                        selected: _source == i,
                                        onTap: () => _selectSource(i),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Font size'),
                                    for (
                                      var i = 0;
                                      i < _sizeOptions.length;
                                      i++
                                    )
                                      _chip(
                                        _sizeOptions[i].$1,
                                        selected: _sizeIndex == i,
                                        onTap: () {
                                          setState(() => _sizeIndex = i);
                                          _log.add(
                                            'subtitle size → ${_sizeOptions[i].$2}×',
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _label('Caption font:', topPadding: 8),
                          Row(
                            children: [
                              for (final (i, label) in [
                                'System (default)',
                                _customFontLabel,
                              ].indexed) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: _chip(
                                    label,
                                    selected: (_captionSerif ? 1 : 0) == i,
                                    onTap: () {
                                      setState(() => _captionSerif = i == 1);
                                      _log.add(
                                        'caption font → ${i == 1 ? _customFontLabel : 'system'}',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                          _label('Volume slider controls:', topPadding: 8),
                          for (final (i, label) in const [
                            'Device volume — hardware buttons move the slider',
                            'Player only — hardware buttons ignored',
                          ].indexed)
                            _chip(
                              label,
                              selected: _volumeMode == i,
                              onTap: () {
                                setState(() => _volumeMode = i);
                                _log.add(
                                  'volume mode → ${i == 0 ? 'device' : 'player only'}',
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 260, child: EventLogView(_log)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../theme.dart';

/// Themed chrome: the SDK's own controls in your brand, through the colour
/// and size tokens on `OGUIConfig` (`colors: OGControlColors(…)`, `dimens:
/// OGControlDimens(…)`). Colours are `#RRGGBB` / `#AARRGGBB` strings, sizes
/// are dp / pt; unset tokens keep the SDK default.
class ThemedChromeDemo extends StatefulWidget {
  const ThemedChromeDemo({super.key});

  @override
  State<ThemedChromeDemo> createState() => _ThemedChromeDemoState();
}

const _brandColors = OGControlColors(
  trackPlayed: '#FF7043',
  thumb: '#FF7043',
  thumbHalo: '#40FF7043',
  trackBuffered: '#90CAF9',
  trackRemaining: '#1E88E5',
  adAccent: '#FF7043',
  menuSurface: '#F20D2A4D',
  menuSelected: '#661E88E5',
  menuBorder: '#801E88E5',
  chipSurface: '#B30D2A4D',
);

const _largeDimens = OGControlDimens(
  trackHeight: 5,
  trackHeightActive: 8,
  thumbSize: 16,
  thumbSizeActive: 22,
  iconSize: 28,
  playButtonSize: 64,
  menuItemHeight: 56,
  menuCorner: 20,
);

const _film = OGMediaItem(
  url: 'https://media.ogplayer.tv/tos/master.m3u8',
  streamType: OGStreamType.vod,
  title: 'Themed chrome',
  posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
);

class _ThemedChromeDemoState extends State<ThemedChromeDemo> {
  bool _isFullscreen = false;

  // 0 = brand colours, 1 = brand colours + larger controls, 2 = SDK default
  int _mode = 0;

  OGUIConfig get _uiConfig => switch (_mode) {
    0 => const OGUIConfig(colors: _brandColors),
    1 => const OGUIConfig(colors: _brandColors, dimens: _largeDimens),
    _ => const OGUIConfig(),
  };

  String get _explainer => switch (_mode) {
    0 =>
      'OGUIConfig(colors: OGControlColors(…)): an orange played track and '
          'thumb over a solid blue bar, a blue menu surface and chips. Open a '
          'menu to see it. Colours are #RRGGBB or #AARRGGBB; unset tokens keep '
          'the SDK default.',
    1 =>
      'dimens: OGControlDimens(…) on top: a thicker track and thumb, larger '
          'option glyphs and play button, taller menu rows with rounder '
          'corners. Sizes are dp / pt and shape the embedded chrome; '
          'fullscreen steps the transport up on its own.',
    _ => "No tokens: the SDK's default white-on-scrim chrome, for comparison.",
  };

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
                'Themed chrome',
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
              // uiConfig is a live prop: a mode switch re-themes the running
              // player, no reload.
              child: OGPlayerView(
                source: _film,
                uiConfig: _uiConfig,
                autoplay: false,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
              ),
            ),
            if (!_isFullscreen)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ScenarioChips(
                      labels: const [
                        'Brand colours',
                        'Brand + larger controls',
                        'SDK default',
                      ],
                      selected: _mode,
                      onSelected: (mode) => setState(() => _mode = mode),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        _explainer,
                        style: const TextStyle(
                          color: InkColors.description,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

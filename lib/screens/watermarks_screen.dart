import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../theme.dart';

/// Watermark showcase: toggle a watermark in ANY of the nine overlay slots
/// (the 3x3 grid mirrors the on-screen positions), live and mid-playback. The
/// SDK keeps them clear of the controls (top slots drop below the top bar,
/// bottom slots lift above it) and hides them during ad breaks. Unlike the
/// native demos' arbitrary composables/views, the Flutter wrapper's overlays
/// are data-driven OverlayConfigs — text here, imageName for logos.
class WatermarksDemo extends StatefulWidget {
  const WatermarksDemo({super.key});

  @override
  State<WatermarksDemo> createState() => _WatermarksDemoState();
}

/// The 9 slots laid out as they appear on screen.
const _slotGrid = <List<OverlaySlot>>[
  [OverlaySlot.topStart, OverlaySlot.topCenter, OverlaySlot.topEnd],
  [OverlaySlot.centerStart, OverlaySlot.center, OverlaySlot.centerEnd],
  [OverlaySlot.bottomStart, OverlaySlot.bottomCenter, OverlaySlot.bottomEnd],
];

String _readableName(OverlaySlot slot) => switch (slot) {
  OverlaySlot.topStart => 'Top-left',
  OverlaySlot.topCenter => 'Top-center',
  OverlaySlot.topEnd => 'Top-right',
  OverlaySlot.centerStart => 'Left',
  OverlaySlot.center => 'Center',
  OverlaySlot.centerEnd => 'Right',
  OverlaySlot.bottomStart => 'Bottom-left',
  OverlaySlot.bottomCenter => 'Bottom-center',
  OverlaySlot.bottomEnd => 'Bottom-right',
};

class _WatermarksDemoState extends State<WatermarksDemo> {
  bool _isFullscreen = false;
  Set<OverlaySlot> _enabled = {OverlaySlot.topEnd};

  static const _item = OGMediaItem(
    url: 'https://media.ogplayer.tv/tos/master.m3u8',
    streamType: OGStreamType.vod,
    title: 'Watermarks',
    posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
  );

  List<OverlayConfig> get _overlays => [
    for (final slot in OverlaySlot.values)
      if (_enabled.contains(slot))
        OverlayConfig(
          slot: slot,
          text: 'WATERMARK ${slot.index + 1}',
          textSize: 12,
        ),
  ];

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
                'Watermarks',
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
                overlays: _overlays,
                autoplay: false,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
              ),
            ),
            if (!_isFullscreen)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tap any slot to place a watermark there — all nine '
                      'positions. The SDK keeps them clear of the controls '
                      '(top slots drop below the top bar, bottom slots lift '
                      'above it).',
                      style: TextStyle(
                        color: InkColors.description,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final rowSlots in _slotGrid)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            for (final slot in rowSlots) ...[
                              if (slot != rowSlots.first)
                                const SizedBox(width: 8),
                              Expanded(child: _slotButton(slot)),
                            ],
                          ],
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

  Widget _slotButton(OverlaySlot slot) {
    final on = _enabled.contains(slot);
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: () => setState(() {
          final next = {..._enabled};
          on ? next.remove(slot) : next.add(slot);
          _enabled = next;
        }),
        style: TextButton.styleFrom(
          backgroundColor: on ? InkColors.accent : InkColors.rowSurface,
          foregroundColor: on ? InkColors.onAccent : InkColors.title,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: on
                ? BorderSide.none
                : const BorderSide(color: InkColors.rowBorder),
          ),
        ),
        child: Text(
          _readableName(slot),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: on ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

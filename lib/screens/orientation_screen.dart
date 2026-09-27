import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../theme.dart';

/// Orientation showcase: an embedded 16:9 player in a portrait page.
/// Tapping the fullscreen button rotates into landscape fullscreen, tapping
/// it again returns to the embedded portrait layout. Sensor rotation does
/// the same (`autoFullscreenOnRotate`).
class OrientationDemo extends StatefulWidget {
  const OrientationDemo({super.key});

  @override
  State<OrientationDemo> createState() => _OrientationDemoState();
}

class _OrientationDemoState extends State<OrientationDemo> {
  bool _isFullscreen = false;

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
                'Orientation & fullscreen',
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
                  title: 'Orientation demo',
                  posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
                  // Storyboard VTT: preview thumbnails appear while scrubbing.
                  thumbnailTrackUrl:
                      'https://media.ogplayer.tv/tos/storyboard/storyboard.vtt',
                ),
                autoplay: false,
                autoFullscreenOnRotate: true,
                onFullscreenChanged: (isFullscreen) =>
                    setState(() => _isFullscreen = isFullscreen),
              ),
            ),
            if (!_isFullscreen)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Embedded 16:9 player.\n\n'
                  'Tap the fullscreen button: the page rotates into '
                  'landscape fullscreen. Tap it again (icon changes to '
                  '“collapse”) and the player returns here, back in '
                  'portrait. Rotating the device physically does the same.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

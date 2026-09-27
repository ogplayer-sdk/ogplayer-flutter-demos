import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

/// Starts directly in fullscreen: `startInFullscreen` invokes the
/// fullscreen path on first frame — landscape, bars hidden. Exiting
/// fullscreen (collapse button or rotation back) returns to the demo
/// list, mirroring the native demos' host-intercepted exit.
class StartFullscreenDemo extends StatefulWidget {
  const StartFullscreenDemo({super.key});

  @override
  State<StartFullscreenDemo> createState() => _StartFullscreenDemoState();
}

class _StartFullscreenDemoState extends State<StartFullscreenDemo> {
  bool _popped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OGPlayerView(
        source: const OGMediaItem(
          url: 'https://media.ogplayer.tv/tos/master.m3u8',
          streamType: OGStreamType.vod,
          title: 'Starts in fullscreen',
          posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
        ),
        autoplay: false,
        startInFullscreen: true,
        autoFullscreenOnRotate: true,
        onFullscreenChanged: (isFullscreen) {
          if (!isFullscreen && !_popped && mounted) {
            _popped = true;
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}

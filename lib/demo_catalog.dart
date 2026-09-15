import 'package:flutter/material.dart';

import 'screens/ads_screen.dart';
import 'screens/cast_screen.dart';
import 'screens/controls_screen.dart';
import 'screens/customactions_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/drm_screen.dart';
import 'screens/errormessages_screen.dart';
import 'screens/live_screen.dart';
import 'screens/nicam_screen.dart';
import 'screens/pip_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/startfullscreen_screen.dart';
import 'screens/tracks_screen.dart';
import 'screens/orientation_screen.dart';
import 'screens/verticalfeed_screen.dart';
import 'screens/watermarks_screen.dart';

/// One demo row in the launcher. [builder] is null while the screen is not
/// yet ported to Flutter — the row renders greyed out with a chip.
class Demo {
  const Demo({
    required this.route,
    required this.title,
    required this.description,
    required this.icon,
    this.tag,
    this.builder,
    this.pendingLabel = 'Soon',
  });

  final String route;
  final String title;
  final String description;
  final IconData icon;
  final String? tag;
  final WidgetBuilder? builder;
  final String pendingLabel;
}

class DemoGroup {
  const DemoGroup(this.header, this.demos);

  final String header;
  final List<Demo> demos;
}

const _nativeOnly = 'Native SDKs only';

final demoGroups = <DemoGroup>[
  DemoGroup('PLAYBACK', [
    Demo(
      route: 'orientation',
      title: 'Orientation & fullscreen',
      description: 'Rotation, embedded ⇄ fullscreen, insets and cutouts.',
      icon: Icons.screen_rotation_outlined,
      builder: (_) => const OrientationDemo(),
    ),
    Demo(
      route: 'controls',
      title: 'Controls on/off',
      description: 'Default chrome, per-control hide, fully headless.',
      icon: Icons.tune_outlined,
      builder: (_) => const ControlsDemo(),
    ),
    Demo(
      route: 'customactions',
      title: 'Custom action icons',
      description: 'Up to 8 host icons inline in the controls, with callbacks.',
      icon: Icons.add_circle_outline,
      builder: (_) => const CustomActionsDemo(),
    ),
    Demo(
      route: 'pip',
      title: 'Picture-in-picture',
      description: 'Auto-enter on Home, dismiss pauses.',
      icon: Icons.picture_in_picture_alt_outlined,
      builder: (_) => const PipDemo(),
    ),
    Demo(
      route: 'startfullscreen',
      title: 'Starts in fullscreen',
      description: 'Opens directly in fullscreen; host-intercepted exit.',
      icon: Icons.open_in_full_outlined,
      builder: (_) => const StartFullscreenDemo(),
    ),
    Demo(
      route: 'playlist',
      title: 'Playlist & up next',
      description:
          'Queue clips that auto-advance, with a themeable countdown card.',
      icon: Icons.playlist_play_outlined,
      builder: (_) => const PlaylistDemo(),
    ),
    Demo(
      route: 'verticalfeed',
      title: 'Vertical feed',
      description:
          'Swipeable portrait feed: preloaded neighbours, loop, sponsored items.',
      icon: Icons.swipe_vertical_outlined,
      builder: (_) => const VerticalFeedDemo(),
    ),
    Demo(
      route: 'errormessages',
      title: 'Custom error messages',
      description: 'Your copy, your language, on our stable error codes.',
      icon: Icons.error_outline,
      builder: (_) => const ErrorMessagesDemo(),
    ),
  ]),
  DemoGroup('STREAMING', [
    Demo(
      route: 'live',
      title: 'Live & DVR',
      description: 'Live edge, seekable window, behind-edge state.',
      icon: Icons.sensors_outlined,
      builder: (_) => const LiveDemo(),
    ),
    Demo(
      route: 'drm',
      title: 'DRM',
      description: 'Licence acquisition and silent recovery.',
      icon: Icons.lock_outline,
      tag: 'Widevine · FairPlay',
      builder: (_) => const DrmDemo(),
    ),
    Demo(
      route: 'downloads',
      title: 'Offline downloads',
      description:
          'Download-to-go with persistent licences — plays in airplane mode.',
      icon: Icons.download_outlined,
      builder: (_) => const DownloadsDemo(),
    ),
  ]),
  DemoGroup('TRACKS & DEVICES', [
    Demo(
      route: 'tracks',
      title: 'Subtitles & audio',
      description: 'Track selection, styling, positioned VTT cues.',
      icon: Icons.closed_caption_outlined,
      builder: (_) => const TracksDemo(),
    ),
    Demo(
      route: 'cast',
      title: 'Chromecast',
      description: 'Discovery, hand-off, remote playback state.',
      icon: Icons.cast_outlined,
      builder: (_) => const CastDemo(),
    ),
  ]),
  DemoGroup('MONETISATION', [
    Demo(
      route: 'ads',
      title: 'Ads',
      description: 'Pre/mid/post-roll pods, skip, cue markers.',
      icon: Icons.movie_outlined,
      tag: 'IMA',
      builder: (_) => const AdsDemo(),
    ),
    const Demo(
      route: 'freewheel',
      title: 'FreeWheel',
      description:
          'Native slot provider, SDK ad chrome. Bring your own FreeWheel SDK.',
      icon: Icons.movie_outlined,
      tag: 'FW',
      pendingLabel: _nativeOnly,
    ),
  ]),
  DemoGroup('OVERLAYS', [
    Demo(
      route: 'watermarks',
      title: 'Watermarks',
      description: 'A watermark in any of nine slots, live.',
      icon: Icons.branding_watermark_outlined,
      builder: (_) => const WatermarksDemo(),
    ),
    Demo(
      route: 'nicam',
      title: 'Content ratings',
      description: 'Age + descriptor icons at program start.',
      icon: Icons.shield_outlined,
      tag: 'Kijkwijzer',
      builder: (_) => const NicamDemo(),
    ),
  ]),
];

Demo? demoForRoute(String route) {
  for (final group in demoGroups) {
    for (final demo in group.demos) {
      if (demo.route == route) return demo;
    }
  }
  return null;
}

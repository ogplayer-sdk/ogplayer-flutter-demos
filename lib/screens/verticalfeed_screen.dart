import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../event_log.dart';
import '../theme.dart';

/// Vertical feed. Portrait-only by design (the component has no
/// fullscreen/rotation API); the plugin pins the activity to portrait while
/// the feed is mounted. A chooser presents the layouts in three groups; each
/// mode gets a fresh analytics log shown from the action bar.
///
/// The natives' "Custom AD badge" and "Errors: custom overlay" variants use
/// composable/SwiftUI slots (sponsoredBadge/errorOverlay) that a data-driven
/// wrapper cannot bridge — same reduction as the React Native demo.
class VerticalFeedDemo extends StatefulWidget {
  const VerticalFeedDemo({super.key});

  @override
  State<VerticalFeedDemo> createState() => _VerticalFeedDemoState();
}

const _base = 'https://media.ogplayer.tv/shorts/v3';

const _portraitClips = <(String, String)>[
  (
    'The memory scan',
    '@tearsofsteel · Forty years on, they scan his memories of her — every '
        'one of them still intact. #scifi #amsterdam',
  ),
  (
    'Forty years later',
    '@tearsofsteel · Old Thom returns to the ruined church where it all '
        'began. #shortfilm',
  ),
  (
    'Sponsored — OGPlayer',
    'One player API — multi-DRM, ads, subtitles, casting. Free to evaluate '
        'at ogplayer.tv',
  ),
  (
    'Rooftops of Amsterdam',
    '@tearsofsteel · The projection sweeps across the old city\'s rooftops. '
        '#vfx #blender',
  ),
  (
    'Face to face',
    '@tearsofsteel · Thom and the machine that remembers him, alone in the '
        'ruins. #robots',
  ),
  (
    'The final projection',
    '@tearsofsteel · He reaches out one last time — made with Blender, '
        'released CC-BY by the Blender Foundation. #ccby',
  ),
];

const _wideClips = <(String, String, OGFeedTextPlacement)>[
  (
    'The old church',
    'Amsterdam\'s canal belt, forty years on. The survivors kept the church '
        'exactly as it was on the night of the projection — every stone, '
        'every cable, every memory of her still wired into the walls.',
    OGFeedTextPlacement.aboveVideo,
  ),
  (
    'Crossing the bridge',
    'Thom walks the Oudezijds bridge one more time. The city looks ordinary '
        '— bicycles, canal houses, tourists — but the machines remember '
        'everything that happened here.',
    OGFeedTextPlacement.belowVideo,
  ),
  (
    'The machine waits',
    'It has stood on the bridge for decades, silent and patient. '
        'Sixteen-by-nine footage sits letterboxed in the feed, and this text '
        'lives in the space above it.',
    OGFeedTextPlacement.aboveVideo,
  ),
];

const _dualPairs = <(String, String, String)>[
  ('01', '04', 'Two sources, one page'),
  ('05', '02', 'Bottom owns the audio here'),
  ('06', '03', 'Bottom follows play/pause'),
];

const _modes = <(String, String, String)>[
  (
    'VERTICAL VIEW',
    'OG vertical view',
    'The feed exactly as the SDK ships it: video, tap-to-pause, progress '
        'hairline. No title, no subtitle, no icons — the right rail is an '
        'empty placeholder your app fills (up to 6 actions).',
  ),
  (
    'VERTICAL VIEW',
    'Custom: icons, title & badge',
    'Titles + subtitles in a custom font, a custom play glyph, and rail '
        'actions with live state — like, share, mute (drives the feed\'s '
        'real mute) and a ⋯ hook.',
  ),
  (
    'SPLIT VIEW',
    'Split screen: text + video',
    'The page splits into a text section and a video section — text above '
        'or below (textPlacement), sized by textBandFraction, with band '
        'background color, custom font and text sizes. Swipe: item 2 has '
        'the text below.',
  ),
  (
    'SPLIT VIEW',
    'Split video: two sources',
    'Two videos on one page — the primary plays on top with audio; the '
        'second plays below, starting when the page is active and '
        'pausing/resuming with the primary (secondaryUrl). Page 2 flips '
        'the audio to the bottom half.',
  ),
  (
    'ERROR HANDLING',
    'Errors: SDK default',
    'Every stream in this feed 404s on purpose. The SDK shows its default '
        'compact error state — message + Retry — and onItemError fires per '
        'item. Swiping past a failed page always works.',
  ),
];

class _VerticalFeedDemoState extends State<VerticalFeedDemo> {
  int? _mode; // null = chooser
  var _liked = <int>{};
  var _shareCounts = {0: 61, 1: 12, 3: 44, 4: 2, 5: 118};
  bool _muted = false;
  EventLogState _analyticsLog = EventLogState();

  static const _likeCounts = {0: 1240, 1: 87, 3: 356, 4: 9, 5: 2031};

  void _pickMode(int mode) {
    final previousLog = _analyticsLog;
    setState(() {
      // Fresh screen per mode: likes, share counts, mute and the log must
      // not leak from the previous mode.
      _liked = {};
      _shareCounts = {0: 61, 1: 12, 3: 44, 4: 2, 5: 118};
      _muted = false;
      _analyticsLog = EventLogState();
      _mode = mode;
    });
    // The ListenableBuilders re-subscribe to the new log during this frame's
    // build; dispose the old one once they have let go of it.
    WidgetsBinding.instance.addPostFrameCallback((_) => previousLog.dispose());
  }

  @override
  void dispose() {
    _analyticsLog.dispose();
    super.dispose();
  }

  static String _formatCount(int n) => switch (n) {
    >= 1000000 => '${(n / 1000000).toStringAsFixed(1)}M',
    >= 1000 => '${(n / 1000).toStringAsFixed(1)}K',
    _ => '$n',
  };

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ── rail (host-owned state: re-supplying items updates it live) ────────

  List<FeedRailAction> _rail(int i, {required bool full}) {
    final like = FeedRailAction(
      iconName: 'og_demo_heart',
      label: _formatCount(
        (_likeCounts[i] ?? 42) + (_liked.contains(i) ? 1 : 0),
      ),
      isActive: _liked.contains(i),
      accessibilityLabel: 'Like',
    );
    final mute = FeedRailAction(
      iconName: _muted ? 'og_demo_volume_off' : 'og_demo_volume_on',
      label: _muted ? 'Unmute' : 'Mute',
      isActive: _muted,
      accessibilityLabel: 'Mute',
    );
    if (!full) return [like, mute];
    return [
      like,
      FeedRailAction(
        iconName: 'og_demo_action_share',
        label: _formatCount(_shareCounts[i] ?? 7),
        accessibilityLabel: 'Share',
      ),
      mute,
      const FeedRailAction(
        iconName: 'og_demo_more',
        accessibilityLabel: 'More',
      ),
    ];
  }

  /// Rail taps arrive as indices; the mapping matches [_rail]'s order.
  void _onRailAction(int itemIndex, int actionIndex) {
    final full = _mode == 1 || _mode == 3;
    if (actionIndex == 0) {
      setState(() {
        _liked.contains(itemIndex)
            ? _liked.remove(itemIndex)
            : _liked.add(itemIndex);
      });
    } else if (full && actionIndex == 1) {
      setState(() {
        _shareCounts[itemIndex] = (_shareCounts[itemIndex] ?? 7) + 1;
      });
      _toast('Share tapped — your share sheet goes here');
    } else if ((full && actionIndex == 2) || (!full && actionIndex == 1)) {
      setState(() => _muted = !_muted);
    } else {
      _toast('Your menu goes here — quality, report, captions…');
    }
  }

  // ── items & config per mode ────────────────────────────────────────────

  List<OGVerticalFeedItem> get _items => switch (_mode) {
    2 => [
      for (final (i, (title, subtitle, placement)) in _wideClips.indexed)
        OGVerticalFeedItem(
          url: '$_base/w169-0${i + 1}.mp4',
          posterUrl: '$_base/w169-0${i + 1}.jpg',
          title: title,
          subtitle: subtitle,
          textPlacement: placement,
          railActions: _rail(i, full: false),
        ),
    ],
    3 => [
      for (final (i, (top, bottom, title)) in _dualPairs.indexed)
        OGVerticalFeedItem(
          url: '$_base/clip$top.mp4',
          posterUrl: '$_base/clip$top.jpg',
          secondaryUrl: '$_base/clip$bottom.mp4',
          splitAudioSource: i == 1
              ? OGFeedSplitAudioSource.secondary
              : OGFeedSplitAudioSource.primary,
          title: title,
          railActions: _rail(i, full: true),
        ),
    ],
    4 => [
      for (var n = 1; n <= 3; n++)
        OGVerticalFeedItem(
          url: '$_base/broken-clip0$n.mp4',
          posterUrl: '$_base/clip0$n.jpg',
          title: 'Broken stream $n',
        ),
    ],
    _ => [
      for (final (i, (title, subtitle)) in _portraitClips.indexed)
        OGVerticalFeedItem(
          url: i == 2 ? '$_base/ad-ogplayer.mp4' : '$_base/clip0${i + 1}.mp4',
          posterUrl: i == 2
              ? '$_base/ad-ogplayer.jpg'
              : '$_base/clip0${i + 1}.jpg',
          title: title,
          subtitle: subtitle,
          sponsored: i == 2,
          // The ad spot has its badge near the frame edge; FIT shows
          // the full frame on every page ratio (bg matches the feed).
          contentFit: i == 2 ? OGFeedContentFit.fit : null,
          railActions: (_mode == 1 && i != 2) ? _rail(i, full: true) : null,
        ),
    ],
  };

  OGVerticalFeedConfig get _config => switch (_mode) {
    1 => const OGVerticalFeedConfig(
      showTitle: true,
      showSubtitle: true,
      textFontFamily: 'serif', // your brand font here
      playIconName: 'og_demo_play_brand',
    ),
    2 => const OGVerticalFeedConfig(
      showTitle: true,
      showSubtitle: true,
      titleTextSize: 19,
      subtitleTextSize: 14,
      textFontFamily: 'serif',
      textBandColor: '#CC141821',
      textBandFraction: 0.36,
    ),
    3 || 4 => const OGVerticalFeedConfig(showTitle: true),
    _ => const OGVerticalFeedConfig(),
  };

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    if (mode == null) return _chooser();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _mode = null);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _mode = null),
                        behavior: HitTestBehavior.opaque,
                        child: const Text(
                          '‹ Modes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        mode == 1 ? 'Vertical feed — custom' : 'Vertical feed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      ListenableBuilder(
                        listenable: _analyticsLog,
                        builder: (context, _) => GestureDetector(
                          onTap: _showAnalytics,
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            'Analytics (${_analyticsLog.entries.length})',
                            style: const TextStyle(
                              color: InkColors.accent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: OGVerticalFeedView(
                  // New identity per mode: full teardown of the previous
                  // mode's player pool — no paused state or page index leaks.
                  key: ValueKey(mode),
                  items: _items,
                  config: _config,
                  muted: _muted,
                  onItemSkipped: (index, reason) =>
                      _toast('Item $index skipped: $reason'),
                  onAnalyticsEvent: (event) =>
                      _analyticsLog.add('analytics: ${event.description}'),
                  // Double-tap is a plain callback — the SDK attaches no
                  // meaning.
                  onItemDoubleTapped: (index) =>
                      _toast('Double-tap on item $index — your action here'),
                  onRailAction: _onRailAction,
                ),
              ),
              const SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    'OGPlayer demo — your tab bar goes here',
                    style: TextStyle(
                      color: InkColors.description,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooser() {
    return Scaffold(
      backgroundColor: InkColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Vertical feed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'One component, five ways to ship it. Pick a mode:',
              style: TextStyle(color: InkColors.description, fontSize: 13),
            ),
            for (final (i, (group, title, body)) in _modes.indexed) ...[
              if (i == 0 || _modes[i - 1].$1 != group)
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 4),
                  child: Text(
                    group,
                    style: TextStyle(
                      color: InkColors.accent.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Material(
                  color: const Color(0xFF17181C),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _pickMode(i),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: InkColors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: const TextStyle(
                              color: Color(0xB8FFFFFF),
                              fontSize: 13,
                              height: 18 / 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAnalytics() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17181C),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        title: const Text('Feed analytics — this session'),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: ListenableBuilder(
            listenable: _analyticsLog,
            builder: (context, _) => _analyticsLog.entries.isEmpty
                ? const Text(
                    'No events yet — swipe through the feed, let a clip loop.',
                    style: TextStyle(
                      color: InkColors.description,
                      fontSize: 13,
                    ),
                  )
                : EventLogView(_analyticsLog),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: InkColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

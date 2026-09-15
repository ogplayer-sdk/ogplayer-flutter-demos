import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../event_log.dart';
import '../theme.dart';

/// Download-to-go: queue a stream for offline playback, watch progress, then
/// play it with networking OFF (airplane mode) — including the DRM'd stream,
/// whose persistent licence (Widevine on Android, FairPlay on iOS) was
/// fetched at download time and is restored at playback with no licence
/// request and no token call.
///
/// - "Clear (ToS)": the Tears of Steel ladder from media.ogplayer.tv.
/// - "Widevine"/"FairPlay": the multi-DRM test vector the DRM demo shares —
///   its entitlement explicitly allows licence persistence
///   (`allow_persistence: true`), so it demonstrates the full offline-DRM
///   lifecycle.
///
/// Playing a download needs no special code — setting the SAME URL as the
/// player's source automatically picks up the local copy.
class DownloadsDemo extends StatefulWidget {
  const DownloadsDemo({super.key});

  @override
  State<DownloadsDemo> createState() => _DownloadsDemoState();
}

// Public multi-DRM test vector JWT; the entitlement message carries
// `allow_persistence: true`, so the
// persistent offline licence can be acquired at download time.
const _persistentToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ewogICJ2ZXJzaW9uIjogMSwKICAiY29tX2tleV9pZCI6ICI2OWU1NDA4OC1lOWUwLTQ1MzAtOGMxYS0xZWI2ZGNkMGQxNGUiLAogICJtZXNzYWdlIjogewogICAgInR5cGUiOiAiZW50aXRsZW1lbnRfbWVzc2FnZSIsCiAgICAidmVyc2lvbiI6IDIsCiAgICAibGljZW5zZSI6IHsKICAgICAgImFsbG93X3BlcnNpc3RlbmNlIjogdHJ1ZQogICAgfSwKICAgICJjb250ZW50X2tleXNfc291cmNlIjogewogICAgICAiaW5saW5lIjogWwogICAgICAgIHsKICAgICAgICAgICJpZCI6ICIzMDJmODBkZC00MTFlLTQ4ODYtYmNhNS1iYjFmODAxOGEwMjQiLAogICAgICAgICAgImVuY3J5cHRlZF9rZXkiOiAicm9LQWcwdDdKaTFpNDNmd3YremZ0UT09IiwKICAgICAgICAgICJ1c2FnZV9wb2xpY3kiOiAiUG9saWN5IEEiCiAgICAgICAgfQogICAgICBdCiAgICB9LAogICAgImNvbnRlbnRfa2V5X3VzYWdlX3BvbGljaWVzIjogWwogICAgICB7CiAgICAgICAgIm5hbWUiOiAiUG9saWN5IEEiLAogICAgICAgICJwbGF5cmVhZHkiOiB7CiAgICAgICAgICAibWluX2RldmljZV9zZWN1cml0eV9sZXZlbCI6IDE1MCwKICAgICAgICAgICJwbGF5X2VuYWJsZXJzIjogWwogICAgICAgICAgICAiNzg2NjI3RDgtQzJBNi00NEJFLThGODgtMDhBRTI1NUIwMUE3IgogICAgICAgICAgXQogICAgICAgIH0KICAgICAgfQogICAgXQogIH0KfQ._NfhLVY7S6k8TJDWPeMPhUawhympnrk6WAZHOVjER6M';

// The DRM scenario's stream URL — download rows are matched back to their
// scenario by URL (DASH for Widevine on Android, HLS for FairPlay on iOS).
final _drmUrl = Platform.isIOS
    ? 'https://media.axprod.net/TestVectors/Cmaf/protected_1080p_h264_cbcs/manifest.m3u8'
    : 'https://media.axprod.net/TestVectors/Cmaf/protected_1080p_h264_cbcs/manifest.mpd';

class _DownloadsDemoState extends State<DownloadsDemo> {
  final _log = EventLogState();
  StreamSubscription<OGDownloadEvent>? _sub;
  bool _isFullscreen = false;
  int _selected = 0;
  List<OGDownload> _downloads = const [];

  /// URL of the download currently loaded into the player, so completion
  /// events don't re-load (and restart) an already-loaded item. Delete
  /// resets the latch (back to the pre-download placeholder).
  String? _loadedDownloadUrl;

  late final List<String> _labels = [
    'Clear (ToS)',
    if (Platform.isIOS) 'FairPlay' else 'Widevine',
  ];

  OGMediaItem _clearItem() => const OGMediaItem(
    url: 'https://media.ogplayer.tv/tos/master.m3u8',
    streamType: OGStreamType.vod,
    title: 'Tears of Steel',
    posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
    thumbnailTrackUrl:
        'https://media.ogplayer.tv/tos/storyboard/storyboard.vtt',
  );

  /// The SAME item for download, deletion and playback — offline pickup is
  /// keyed by URL. The token's entitlement allows licence persistence.
  OGMediaItem _drmItem() => OGMediaItem(
    url: _drmUrl,
    streamType: OGStreamType.vod,
    title: 'Multi-DRM demo (encrypted)',
    posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
    drm: Platform.isIOS
        ? const DrmConfig(
            fairplay: FairPlayConfig(
              certificateUrl: 'https://tools.axinom.com/FPScert/fairplay.cer',
              licenseUrl:
                  'https://drm-fairplay-licensing.axprod.net/AcquireLicense',
              headers: {'X-AxDRM-Message': _persistentToken},
            ),
          )
        : DrmConfig(
            widevine: const WidevineConfig(
              licenseUrl:
                  'https://drm-widevine-licensing.axprod.net/AcquireLicense',
            ),
            tokenHeaderName: 'X-AxDRM-Message',
            tokenProvider: (request) async {
              // Resolved Dart-side once per downloads call: the offline
              // licence fetch at download time, and the release request
              // on Delete — never during offline play.
              if (mounted) {
                _log.add(
                  'tokenProvider called '
                  '(${request.renewal ? 'renewal/release' : 'licence'})',
                );
              }
              return {'X-AxDRM-Message': _persistentToken};
            },
          ),
  );

  OGMediaItem _itemFor(String url) =>
      url == _drmUrl ? _drmItem() : _clearItem();

  @override
  void initState() {
    super.initState();
    _sub = OGDownloads.events.listen(_onDownloadEvent);
    // Restart persistence: a download completed in a previous process
    // (force-kill skips demo cleanup) goes straight into the player.
    _refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Demo hygiene: leaving the screen deletes the downloads. The DRM'd
    // download gets its item so the Widevine release request can
    // authenticate (frees the server-side offline slot; iOS erases FairPlay
    // keys locally and ignores the item).
    for (final d in _downloads) {
      unawaited(
        OGDownloads.remove(d.url, d.url == _drmUrl ? _drmItem() : null),
      );
    }
    _log.dispose();
    super.dispose();
  }

  void _onDownloadEvent(OGDownloadEvent event) {
    switch (event) {
      case OGDownloadStateChanged(:final download):
        _log.add(
          'download ${download.state.name.toUpperCase()}: '
          '${download.title ?? download.url}',
        );
      case OGDownloadFailed(:final download, :final error):
        // Include the message — "7100" alone hides e.g. an offline device
        // behind an opaque code.
        _log.add(
          'download FAILED ${error.code} ${error.category}: ${error.message} '
          '(${download.title ?? download.url})',
        );
      case OGDownloadProgress():
        break; // rows below show the percentage
    }
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await OGDownloads.list();
    if (!mounted) return;
    setState(() => _downloads = list);
    _loadCompletedIfNeeded();
  }

  /// A COMPLETED download auto-loads into the player (paused) exactly once —
  /// the player's own play button is the demo's play control. Offline pickup
  /// is keyed by URL, no special code.
  void _loadCompletedIfNeeded() {
    OGDownload? completed;
    for (final d in _downloads) {
      if (d.state == OGDownloadState.completed) {
        completed = d;
        break;
      }
    }
    if (completed == null) {
      // Delete → back to the pre-download placeholder (removing the view
      // stops playback, nothing can keep sounding behind it).
      if (_downloads.isEmpty && _loadedDownloadUrl != null) {
        setState(() => _loadedDownloadUrl = null);
      }
      return;
    }
    if (_loadedDownloadUrl == completed.url) return;
    final item = _itemFor(completed.url);
    setState(() => _loadedDownloadUrl = completed!.url);
    _log.add(
      '— ${item.title} downloaded, loading into the player (plays offline) —',
    );
  }

  Future<void> _download() async {
    final item = _selected == 0 ? _clearItem() : _drmItem();
    _log.add('— queueing ${_labels[_selected]} (720p cap) —');
    await OGDownloads.add(item, const OGDownloadConfig(maxVideoHeight: 720));
    _refresh();
  }

  Future<void> _delete(OGDownload d) async {
    // Pass the item for DRM'd downloads so the Widevine release request can
    // authenticate (frees the server-side offline slot, not just local data).
    await OGDownloads.remove(d.url, d.url == _drmUrl ? _drmItem() : null);
    _refresh();
  }

  /// "title · state · percent · licence info" — mirrors the native demo rows.
  String _summary(OGDownload d) {
    var text = '${d.title ?? d.url} · ${d.state.name.toUpperCase()}';
    if (d.progressPercent >= 0) text += ' ${d.progressPercent.toInt()}%';
    final lic = d.license;
    if (lic != null) {
      final t = lic.expiresAtMs;
      if (t == null) {
        text += ' · licence unlimited';
      } else {
        final dt = DateTime.fromMillisecondsSinceEpoch(t);
        String two(int n) => n.toString().padLeft(2, '0');
        text +=
            ' · licence ${lic.isExpired ? 'EXPIRED' : 'until'} '
            '${dt.year}-${two(dt.month)}-${two(dt.day)} '
            '${two(dt.hour)}:${two(dt.minute)}';
      }
    }
    return text;
  }

  ButtonStyle get _rowButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: InkColors.accent,
    visualDensity: VisualDensity.compact,
  );

  Widget _downloadRow(OGDownload d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _summary(d),
              style: const TextStyle(color: InkColors.title, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          if (d.state == OGDownloadState.downloading ||
              d.state == OGDownloadState.queued)
            OutlinedButton(
              onPressed: () => OGDownloads.pause(d.url).then((_) => _refresh()),
              style: _rowButtonStyle,
              child: const Text('Pause', style: TextStyle(fontSize: 12)),
            )
          else if (d.state == OGDownloadState.paused ||
              d.state == OGDownloadState.failed)
            OutlinedButton(
              onPressed: () =>
                  OGDownloads.resume(d.url).then((_) => _refresh()),
              style: _rowButtonStyle,
              child: const Text('Resume', style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _delete(d),
            style: _rowButtonStyle,
            child: const Text('Delete', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
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
                'Offline downloads',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        child: Column(
          children: [
            if (_loadedDownloadUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: OGPlayerView(
                  source: _itemFor(_loadedDownloadUrl!),
                  autoplay: false,
                  autoFullscreenOnRotate: true,
                  onFullscreenChanged: (isFullscreen) =>
                      setState(() => _isFullscreen = isFullscreen),
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
              )
            else
              // Pre-download placeholder where the player will appear —
              // returns after Delete (the finished download auto-loads).
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      'Download below — the finished download loads here.',
                      style: TextStyle(
                        color: InkColors.description,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_isFullscreen) ...[
              // One download at a time: while anything is downloaded or in
              // flight, the stream chooser and Download button give way to
              // the download's own row — Delete brings the choices back.
              // A COMPLETED download auto-loads into the player above, so
              // its own play button is the only play control (the row keeps
              // just Delete).
              if (_downloads.isEmpty) ...[
                ScenarioChips(
                  labels: _labels,
                  selected: _selected,
                  onSelected: (index) => setState(() => _selected = index),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed: _download,
                      style: _rowButtonStyle,
                      child: const Text(
                        'Download',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
              ..._downloads.map(_downloadRow),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Download, then toggle airplane mode and press play on '
                      'the player — both streams keep playing. The DRM '
                      'stream restores its persistent licence with no '
                      'network and no token call.',
                      style: TextStyle(
                        color: InkColors.description,
                        fontSize: 12,
                      ),
                    ),
                    if (Platform.isIOS)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'FairPlay requires a real device — the DRM\'d '
                          'download fails on the Simulator.',
                          style: TextStyle(
                            color: InkColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
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

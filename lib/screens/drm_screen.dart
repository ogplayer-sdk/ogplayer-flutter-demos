import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../event_log.dart';
import '../theme.dart';

/// DRM showcase — platform-branched scenarios mirroring the native demos.
///
/// Android (Widevine):
/// - "Widevine (open)": Google's test asset against the public widevine_test
///   license proxy — plain licenseUrl, no token.
/// - "Token header": a public multi-DRM test vector where a JWT travels in
///   X-AxDRM-Message. The SDK calls the tokenProvider back into Dart on EVERY
///   license request (watch the log) — the mechanism that fixes the classic
///   frozen-token/resume-after-pause failure.
///
/// iOS (FairPlay — requires a real device, keys don't work on the Simulator):
/// - "FairPlay (open)": EZDRM public test asset, static config only.
/// - "Token header": same stream + a per-request tokenProvider minting a demo
///   X-Demo-Token header (EZDRM's public KSM ignores it, playback still works).
/// - "Multi-DRM (shared)": the same encrypted stream, FairPlay flavor.
class DrmDemo extends StatefulWidget {
  const DrmDemo({super.key});

  @override
  State<DrmDemo> createState() => _DrmDemoState();
}

// Public multi-DRM test vector JWT (allow_persistence entitlement).
const _sharedToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ewogICJ2ZXJzaW9uIjogMSwKICAiY29tX2tleV9pZCI6ICI2OWU1NDA4OC1lOWUwLTQ1MzAtOGMxYS0xZWI2ZGNkMGQxNGUiLAogICJtZXNzYWdlIjogewogICAgInR5cGUiOiAiZW50aXRsZW1lbnRfbWVzc2FnZSIsCiAgICAidmVyc2lvbiI6IDIsCiAgICAibGljZW5zZSI6IHsKICAgICAgImFsbG93X3BlcnNpc3RlbmNlIjogdHJ1ZQogICAgfSwKICAgICJjb250ZW50X2tleXNfc291cmNlIjogewogICAgICAiaW5saW5lIjogWwogICAgICAgIHsKICAgICAgICAgICJpZCI6ICIzMDJmODBkZC00MTFlLTQ4ODYtYmNhNS1iYjFmODAxOGEwMjQiLAogICAgICAgICAgImVuY3J5cHRlZF9rZXkiOiAicm9LQWcwdDdKaTFpNDNmd3YremZ0UT09IiwKICAgICAgICAgICJ1c2FnZV9wb2xpY3kiOiAiUG9saWN5IEEiCiAgICAgICAgfQogICAgICBdCiAgICB9LAogICAgImNvbnRlbnRfa2V5X3VzYWdlX3BvbGljaWVzIjogWwogICAgICB7CiAgICAgICAgIm5hbWUiOiAiUG9saWN5IEEiLAogICAgICAgICJwbGF5cmVhZHkiOiB7CiAgICAgICAgICAibWluX2RldmljZV9zZWN1cml0eV9sZXZlbCI6IDE1MCwKICAgICAgICAgICJwbGF5X2VuYWJsZXJzIjogWwogICAgICAgICAgICAiNzg2NjI3RDgtQzJBNi00NEJFLThGODgtMDhBRTI1NUIwMUE3IgogICAgICAgICAgXQogICAgICAgIH0KICAgICAgfQogICAgXQogIH0KfQ._NfhLVY7S6k8TJDWPeMPhUawhympnrk6WAZHOVjER6M';

// EZDRM public FairPlay test endpoints (same asset for the open and token
// chips — only the license-request credentials differ).
const _ezdrmCertificateUrl = 'https://fps.ezdrm.com/demo/video/eleisure.cer';
const _ezdrmLicenseUrl =
    'https://fps.ezdrm.com/api/licenses/09cc0377-6dd4-40cb-b09d-b582236e70fe';

class _DrmDemoState extends State<DrmDemo> {
  final _log = EventLogState();
  bool _isFullscreen = false;
  int _selected = 0;

  late final List<String> _labels = Platform.isIOS
      ? const ['FairPlay (open)', 'Token header', 'Multi-DRM (shared)']
      : const ['Widevine (open)', 'Token header'];

  @override
  void initState() {
    super.initState();
    _log.add('— loading ${_labels[_selected]} —');
  }

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _log.add('— loading ${_labels[index]} —');
  }

  OGMediaItem _buildItem() {
    if (Platform.isIOS) {
      switch (_selected) {
        case 1:
          return OGMediaItem(
            url: 'https://fps.ezdrm.com/demo/video/ezdrm.m3u8',
            streamType: OGStreamType.vod,
            title: 'FairPlay (EZDRM)',
            drm: DrmConfig(
              fairplay: const FairPlayConfig(
                certificateUrl: _ezdrmCertificateUrl,
                licenseUrl: _ezdrmLicenseUrl,
              ),
              tokenHeaderName: 'X-Demo-Token',
              tokenProvider: (request) async {
                // Called fresh on EVERY license request (incl. renewals) —
                // fetch/refresh a real token here. EZDRM's public KSM ignores
                // the extra header, so playback still works.
                final token =
                    'demo-${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
                _log.add(
                  'tokenProvider: issued token for ${request.licenseUrl}',
                );
                return {'X-Demo-Token': token};
              },
            ),
          );
        case 2:
          return OGMediaItem(
            url: 'https://media.axprod.net/TestVectors/Cmaf/protected_1080p_h264_cbcs/manifest.m3u8',
            streamType: OGStreamType.vod,
            title: 'Multi-DRM demo (encrypted)',
            drm: const DrmConfig(
              fairplay: FairPlayConfig(
                certificateUrl: 'https://tools.axinom.com/FPScert/fairplay.cer',
                licenseUrl:
                    'https://drm-fairplay-licensing.axprod.net/AcquireLicense',
                headers: {'X-AxDRM-Message': _sharedToken},
              ),
            ),
          );
        default:
          return const OGMediaItem(
            url: 'https://fps.ezdrm.com/demo/video/ezdrm.m3u8',
            streamType: OGStreamType.vod,
            title: 'FairPlay (EZDRM)',
            drm: DrmConfig(
              fairplay: FairPlayConfig(
                certificateUrl: _ezdrmCertificateUrl,
                licenseUrl: _ezdrmLicenseUrl,
              ),
            ),
          );
      }
    }
    switch (_selected) {
      case 1:
        // The same encrypted stream, DASH flavor.
        return OGMediaItem(
          url: 'https://media.axprod.net/TestVectors/Cmaf/protected_1080p_h264_cbcs/manifest.mpd',
          streamType: OGStreamType.vod,
          title: 'Multi-DRM demo (encrypted)',
          posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
          drm: DrmConfig(
            widevine: const WidevineConfig(
              licenseUrl:
                  'https://drm-widevine-licensing.axprod.net/AcquireLicense',
            ),
            tokenHeaderName: 'X-AxDRM-Message',
            tokenProvider: (request) async {
              // Called fresh on EVERY license request (incl. renewals) —
              // fetch/refresh a real token here.
              _log.add('tokenProvider called (renewal=${request.renewal})');
              return {'X-AxDRM-Message': _sharedToken};
            },
          ),
        );
      default:
        return const OGMediaItem(
          url: 'https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd',
          streamType: OGStreamType.vod,
          title: 'Tears — Widevine test asset',
          posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
          drm: DrmConfig(
            widevine: WidevineConfig(
              licenseUrl:
                  'https://proxy.uat.widevine.com/proxy?provider=widevine_test',
            ),
          ),
        );
    }
  }

  /// Follows [_buildItem]: what each chrome button has behind it depends on
  /// the selected stream. Cast/AirPlay isn't relevant to this scenario
  /// (mirrors the native iOS demo hiding the AirPlay button).
  OGUIConfig get _uiConfig {
    if (Platform.isIOS) {
      switch (_selected) {
        case 2:
          // The shared cbcs HLS vector: three audio and three text tracks, five
          // variants — every menu has entries.
          return const OGUIConfig(showCastButton: false);
        default:
          // EZDRM FairPlay: a single media playlist — one audio track, no
          // text tracks, no ladder.
          return const OGUIConfig(
            showCastButton: false,
            showSubtitleButton: false,
            showAudioTrackButton: false,
            showQualityButton: false,
          );
      }
    }
    switch (_selected) {
      case 1:
        // The shared cbcs DASH vector: three audio and three text tracks, five
        // variants — every menu has entries.
        return const OGUIConfig(showCastButton: false);
      default:
        // Google's Widevine test asset: one audio track, no text tracks;
        // the ladder is real, so quality stays.
        return const OGUIConfig(
          showCastButton: false,
          showSubtitleButton: false,
          showAudioTrackButton: false,
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
                'DRM',
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
                uiConfig: _uiConfig,
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
            ),
            if (!_isFullscreen) ...[
              ScenarioChips(
                labels: _labels,
                selected: _selected,
                onSelected: _select,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Platform.isIOS
                          ? 'FairPlay Streaming — EZDRM public test asset. '
                                'The SDK fetches the app certificate, builds '
                                'the SPC, calls the KSM and installs the CKC. '
                                'The token chip adds a per-request '
                                'tokenProvider — watch it log on every '
                                'license call. The EZDRM stream is a single '
                                'media playlist — one audio track, no '
                                'subtitles, no ladder — so its subtitle, '
                                'audio and quality buttons are hidden; the '
                                'Multi-DRM stream carries three audio and '
                                'three subtitle tracks and a five-variant '
                                'ladder, so nothing is hidden there.'
                          : 'Watch for DrmKeysLoaded in the log; the '
                                'token-header stream also logs each '
                                "tokenProvider call. Google's Widevine test "
                                'asset has one audio track and no subtitles, '
                                'so the subtitle and audio buttons are hidden '
                                '(the ladder is real, so quality stays); the '
                                'token-header stream carries three audio and '
                                'three subtitle tracks, so nothing is hidden '
                                'there.',
                      style: const TextStyle(
                        color: InkColors.description,
                        fontSize: 12,
                      ),
                    ),
                    if (Platform.isIOS)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "Requires a real device — FairPlay keys don't "
                          'work on the Simulator.',
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

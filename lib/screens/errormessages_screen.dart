import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../theme.dart';

/// Custom error messages: the host maps the SDK's stable error codes (2000
/// network, 3000 source, 4000 DRM, 5000 renderer, 6000 live, 9000 unknown) to
/// its own copy in any language via the `errorMessages` map. This screen loads
/// a stream URL that doesn't exist, so playback always fails — type a message
/// and reload to see yours on the error overlay. The raw OGPlayerError still
/// reaches onError unchanged.
class ErrorMessagesDemo extends StatefulWidget {
  const ErrorMessagesDemo({super.key});

  @override
  State<ErrorMessagesDemo> createState() => _ErrorMessagesDemoState();
}

const _missingStream = 'https://media.ogplayer.tv/tos/does-not-exist.m3u8';

class _ErrorMessagesDemoState extends State<ErrorMessagesDemo> {
  final _messageField = TextEditingController();
  OGPlayerViewController? _controller;
  bool _isFullscreen = false;

  // Retry demo modes: the SDK button as-is, a relabeled one, none at all,
  // a fully host-owned overlay, or the branded (themed) SDK overlay.
  // 0=SDK, 1=label, 2=none, 3=custom overlay, 4=branded
  int _mode = 0;

  /// The message text as of the last Reload — the errorMessages map is
  /// uiConfig, so it applies on the next (failing) load, not per keystroke.
  String _appliedMessage = '';

  /// Last error, for the mode-3 host-owned panel.
  OGPlayerError? _lastError;

  @override
  void dispose() {
    _messageField.dispose();
    super.dispose();
  }

  OGUIConfig get _uiConfig => OGUIConfig(
    // Nothing ever loads here: seek, timeline, speed and the track menus
    // would act on no content, so they're hidden. Play/pause, volume and
    // fullscreen stay.
    showSeekButtons: false,
    showProgressBar: false,
    showTimeLabels: false,
    showSpeedButton: false,
    showQualityButton: false,
    showAudioTrackButton: false,
    showSubtitleButton: false,
    showRetryButton: _mode != 2,
    retryButtonLabel: _mode == 1 ? 'Probeer opnieuw' : null,
    // Mode 3: hide the SDK overlay entirely — onError still fires and
    // the app draws its own panel over the player (see build()).
    suppressErrorOverlay: _mode == 3 ? true : null,
    errorMessages: _appliedMessage.trim().isEmpty
        ? null
        : {'default': _appliedMessage.trim()},
    // Branded: serif text + a blue button prove the SDK look is not
    // baked in.
    errorTextColor: _mode == 4 ? '#FFFFFFFF' : null,
    errorTextSize: _mode == 4 ? 16 : null,
    errorTextFontFamily: _mode == 4 ? 'serif' : null,
    retryButtonColor: _mode == 4 ? '#FF3D6EF5' : null,
    retryButtonTextColor: _mode == 4 ? '#FFFFFFFF' : null,
    retryButtonFontFamily: _mode == 4 ? 'serif' : null,
  );

  String get _explainer => switch (_mode) {
    3 =>
      'suppressErrorOverlay + onError — the panel over the player is '
          '100% app UI drawn by Flutter, with the error in hand and '
          'controller.retry() to recover.',
    2 =>
      'showRetryButton: false — the overlay shows only your message; '
          "recovery is your app's call.",
    1 =>
      "retryButtonLabel: 'Probeer opnieuw' — the SDK's Retry button, "
          'your text, any language.',
    _ =>
      'This screen loads a missing stream URL, so it always fails — '
          'your text (any language) replaces the SDK\'s default error '
          'overlay via the errorMessages map.',
  };

  /// The failing source never changes, so a source-prop swap won't reload —
  /// retry() re-runs the load. The new uiConfig only reaches native on this
  /// frame's didUpdateWidget → setUiConfig, so the retry is deferred to after
  /// the frame: same channel, in order, so it runs against the NEW config.
  void _reload() {
    setState(() {
      _appliedMessage = _messageField.text;
      _lastError = null;
    });
    _retryAfterFrame();
  }

  void _selectMode(int mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _lastError = null;
    });
    _retryAfterFrame();
  }

  void _retryAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller?.retry();
    });
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
                'Custom error messages',
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OGPlayerView(
                    source: OGMediaItem(
                      url: _missingStream,
                      streamType: OGStreamType.vod,
                      title: 'Custom error demo',
                    ),
                    uiConfig: _uiConfig,
                    autoplay: true,
                    autoFullscreenOnRotate: true,
                    onViewCreated: (controller) => _controller = controller,
                    onFullscreenChanged: (isFullscreen) =>
                        setState(() => _isFullscreen = isFullscreen),
                    onError: (error) => setState(() => _lastError = error),
                  ),
                  if (_mode == 3 && _lastError != null)
                    _HostErrorPanel(
                      error: _lastError!,
                      onRetry: () {
                        setState(() => _lastError = null);
                        _controller?.retry();
                      },
                    ),
                ],
              ),
            ),
            if (!_isFullscreen)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageField,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              labelText:
                                  'Your error message — {code} = error code',
                              labelStyle: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _reload,
                          style: FilledButton.styleFrom(
                            backgroundColor: InkColors.accent,
                            foregroundColor: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Reload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ScenarioChips(
                      labels: const [
                        'SDK Retry',
                        'Custom label',
                        'No retry button',
                        'Custom overlay',
                        'Branded style',
                      ],
                      selected: _mode,
                      onSelected: _selectMode,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        '$_explainer Nothing plays here, so the seek, '
                        'timeline, speed and track controls are hidden; '
                        'play/pause, volume and fullscreen stay.',
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

/// 100% host-owned error UI for the "Custom overlay" mode — deliberately
/// styled unlike the SDK chrome (accent card, rounded button) to make clear
/// this is the app's design language, not OGPlayer's.
class _HostErrorPanel extends StatelessWidget {
  const _HostErrorPanel({required this.error, required this.onRetry});

  final OGPlayerError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6121317),
      child: Center(
        // Compact: must fit inside an embedded 16:9 player on a phone.
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1F24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '😕  Something broke on our side',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Error ${error.code} — this whole panel is the demo app's UI.",
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: InkColors.accent,
                  foregroundColor: const Color(0xFF131313),
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

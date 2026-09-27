import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../theme.dart';

/// Control-visibility playground: every built-in control has an on/off
/// switch, plus the master "Hide all controls" and a "Live content" toggle
/// that reloads to a live stream (LIVE chip). OGUIConfig is a widget prop,
/// so changes apply to the running player instantly — no reload needed.
class ControlsDemo extends StatefulWidget {
  const ControlsDemo({super.key});

  @override
  State<ControlsDemo> createState() => _ControlsDemoState();
}

class _ControlsDemoState extends State<ControlsDemo> {
  static const _vod = OGMediaItem(
    url: 'https://media.ogplayer.tv/tos/master.m3u8',
    streamType: OGStreamType.vod,
    title: 'Controls playground',
    posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
  );
  static const _live = OGMediaItem(
    url: 'https://demo.unified-streaming.com/k8s/live/stable/live.isml/.m3u8',
    streamType: OGStreamType.liveDvr,
    title: 'Controls playground — live',
    posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
  );

  bool _isFullscreen = false;
  bool _hideAll = false;
  bool _liveContent = false;

  bool _seekButtons = true;
  bool _progressBar = true;
  bool _timeLabels = true;
  bool _subtitleButton = true;
  bool _audioTrackButton = true;
  bool _qualityButton = true;
  bool _speedButton = true;
  bool _volumeButton = true;
  bool _castButton = true;
  bool _fullscreenButton = true;

  OGUIConfig get _uiConfig => _hideAll
      ? const OGUIConfig(hideAllControls: true)
      : OGUIConfig(
          showSeekButtons: _seekButtons,
          showProgressBar: _progressBar,
          showTimeLabels: _timeLabels,
          showSubtitleButton: _subtitleButton,
          showAudioTrackButton: _audioTrackButton,
          showQualityButton: _qualityButton,
          showSpeedButton: _speedButton,
          showVolumeButton: _volumeButton,
          showCastButton: _castButton,
          showFullscreenButton: _fullscreenButton,
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
                'Controls on/off',
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
                source: _liveContent ? _live : _vod,
                uiConfig: _uiConfig,
                autoplay: false,
                castEnabled: true,
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Flip a switch — the running player updates '
                        'instantly (OGUIConfig is state; no reload). '
                        'Play/pause and the LIVE chip are always visible '
                        'by SDK design.',
                        style: TextStyle(
                          color: InkColors.description,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _switchRow(
                      'Live content (shows LIVE chip)',
                      _liveContent,
                      bold: true,
                      master: true,
                      onChanged: (v) => setState(() => _liveContent = v),
                    ),
                    _switchRow(
                      'Hide all controls',
                      _hideAll,
                      bold: true,
                      master: true,
                      onChanged: (v) => setState(() => _hideAll = v),
                    ),
                    const Divider(
                      color: InkColors.rowBorder,
                      height: 16,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _switchRow(
                      'Seek buttons (±10s)',
                      _seekButtons,
                      onChanged: (v) => setState(() => _seekButtons = v),
                    ),
                    _switchRow(
                      'Progress bar',
                      _progressBar,
                      onChanged: (v) => setState(() => _progressBar = v),
                    ),
                    _switchRow(
                      'Time labels',
                      _timeLabels,
                      onChanged: (v) => setState(() => _timeLabels = v),
                    ),
                    _switchRow(
                      'Subtitle button',
                      _subtitleButton,
                      onChanged: (v) => setState(() => _subtitleButton = v),
                    ),
                    _switchRow(
                      'Audio-track button',
                      _audioTrackButton,
                      onChanged: (v) => setState(() => _audioTrackButton = v),
                    ),
                    _switchRow(
                      'Quality button',
                      _qualityButton,
                      onChanged: (v) => setState(() => _qualityButton = v),
                    ),
                    _switchRow(
                      'Speed button',
                      _speedButton,
                      onChanged: (v) => setState(() => _speedButton = v),
                    ),
                    _switchRow(
                      'Volume button',
                      _volumeButton,
                      onChanged: (v) => setState(() => _volumeButton = v),
                    ),
                    _switchRow(
                      Platform.isIOS ? 'AirPlay button' : 'Cast button',
                      _castButton,
                      onChanged: (v) => setState(() => _castButton = v),
                    ),
                    _switchRow(
                      'Fullscreen button',
                      _fullscreenButton,
                      onChanged: (v) => setState(() => _fullscreenButton = v),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Master rows stay active while "Hide all controls" is on; per-control
  /// rows dim and show off, mirroring the native demos.
  Widget _switchRow(
    String label,
    bool value, {
    bool bold = false,
    bool master = false,
    required ValueChanged<bool> onChanged,
  }) {
    final enabled = master || !_hideAll;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? InkColors.title : InkColors.description,
                  fontSize: bold ? 15 : 14,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Switch(
              value: enabled && value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: InkColors.onAccent,
              activeTrackColor: InkColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

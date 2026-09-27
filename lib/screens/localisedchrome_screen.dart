import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ogplayer_flutter/ogplayer_flutter.dart';

import '../chip_row.dart';
import '../theme.dart';

/// Localised chrome: every word the player shows or speaks to the screen
/// reader comes from one [OGStrings] — here a complete Dutch set — handed to
/// `OGUIConfig(strings: …)`. The keys are the same in every OGPlayer SDK, so
/// `OGStrings.fromMap` takes the very map an app keeps for its other players.
/// The strings live in the app; the SDK ships English and never guesses a
/// language from the device.
class LocalisedChromeDemo extends StatefulWidget {
  const LocalisedChromeDemo({super.key});

  @override
  State<LocalisedChromeDemo> createState() => _LocalisedChromeDemoState();
}

const _dutch = OGStrings(
  play: 'Afspelen',
  pause: 'Pauzeren',
  replay: 'Opnieuw afspelen',
  seekForward: '{seconds} seconden vooruit',
  seekBackward: '{seconds} seconden terug',
  next: 'Volgende',
  previous: 'Vorige',
  volume: 'Volume',
  mute: 'Dempen',
  unmute: 'Dempen opheffen',
  enterFullscreen: 'Volledig scherm',
  exitFullscreen: 'Volledig scherm sluiten',
  seekBar: 'Afspeelpositie',
  customAction: 'Actie {n}',
  subtitles: 'Ondertiteling',
  subtitlesOff: 'Uit',
  audio: 'Audio',
  playbackSpeed: 'Afspeelsnelheid',
  speedNormal: 'Normaal',
  speedValue: '{speed}×',
  quality: 'Videokwaliteit',
  qualityAuto: 'Automatisch',
  qualityHeight: '{height}p',
  qualityBitrate: '{kbps} kbps',
  qualityAdaptive: 'adaptief',
  audioDefault: 'Standaard',
  trackUnknown: 'Onbekend',
  audioFallback: 'Audio {n}',
  subtitlesFallback: 'Ondertiteling {n}',
  audioChannels: '{name} · {channels} kanalen',
  live: 'LIVE',
  goLive: 'Naar live',
  upNext: 'Volgende over {seconds}',
  playNext: 'Volgende afspelen: {title}',
  nextVideo: 'volgende video',
  ad: 'RECLAME',
  adPod: '{index} van {count}',
  learnMore: 'Meer informatie',
  skipAd: 'Advertentie overslaan',
  skipIn: 'Overslaan over {seconds}',
  pauseAd: 'Advertentie pauzeren',
  resumeAd: 'Advertentie hervatten',
  adBlockedTitle: 'Advertenties worden geblokkeerd',
  adBlockedText:
      'Deze video wordt aangeboden met advertenties, maar je adblocker houdt '
      'ze tegen.',
  adBlockedTextHard:
      'Deze video is alleen beschikbaar met advertenties. Schakel je '
      'adblocker uit en laad de pagina opnieuw.',
  adBlockedDismiss: 'Begrepen',
  adBlockedReload: 'Uitgeschakeld — opnieuw laden',
  dismiss: 'Sluiten',
  errorGeneric: 'Afspeelfout {code}',
  retry: 'Opnieuw proberen',
  downloading: 'Downloaden',
  downloadingItemsOne: '1 item downloaden',
  downloadingItems: '{count} items downloaden',
  cast: 'Casten',
  castConnecting: 'Verbinden met cast-apparaat',
  casting: 'Bezig met casten',
  castConnectingStatus: 'Verbinden…',
  castingTo: 'Casten naar {device}',
  airPlay: 'AirPlay',
  airPlayTo: 'AirPlay — {device}',
  pipPlaying: 'Speelt af in beeld-in-beeld',
  sponsored: 'Gesponsord',
);

/// Tears of Steel: five subtitle languages and three audio tracks in one
/// manifest — every menu has rows to show.
const _film = OGMediaItem(
  url: 'https://media.ogplayer.tv/tos/master.m3u8',
  streamType: OGStreamType.vod,
  title: 'Tears of Steel',
  posterUrl: 'https://media.ogplayer.tv/posters/tos-mech.jpg',
);

const _live = OGMediaItem(
  url: 'https://demo.unified-streaming.com/k8s/live/stable/live.isml/.m3u8',
  streamType: OGStreamType.liveDvr,
  title: 'Live',
);

/// A URL that never loads — the errors demo's pattern, for the overlay copy.
const _missing = OGMediaItem(
  url: 'https://media.ogplayer.tv/tos/does-not-exist.m3u8',
  streamType: OGStreamType.vod,
  title: 'Tears of Steel',
);

class _LocalisedChromeDemoState extends State<LocalisedChromeDemo> {
  bool _isFullscreen = false;

  // 0 = on demand, 1 = live DVR, 2 = error overlay
  int _mode = 0;

  OGUIConfig get _uiConfig => switch (_mode) {
    // The live stream carries no subtitles and one audio language.
    1 => const OGUIConfig(
      strings: _dutch,
      showCastButton: false,
      showSubtitleButton: false,
      showAudioTrackButton: false,
    ),
    // Nothing plays: no timeline, rate or tracks to act on.
    2 => const OGUIConfig(
      strings: _dutch,
      showCastButton: false,
      showSeekButtons: false,
      showProgressBar: false,
      showTimeLabels: false,
      showSpeedButton: false,
      showQualityButton: false,
      showAudioTrackButton: false,
      showSubtitleButton: false,
    ),
    _ => const OGUIConfig(strings: _dutch, showCastButton: false),
  };

  OGMediaItem get _source => switch (_mode) {
    1 => _live,
    2 => _missing,
    _ => _film,
  };

  String get _explainer => switch (_mode) {
    1 =>
      'Live with a seekable window: the LIVE chip and the behind-live '
          'readout; the chip\'s action is spoken as "Naar live".',
    2 =>
      'A stream that never loads: the overlay shows errorGeneric '
          '("Afspeelfout {code}") and the Retry button reads "Opnieuw '
          'proberen". errorMessages and retryButtonLabel still win when set.',
    _ =>
      'One Dutch OGStrings relabels the whole chrome: open the subtitle, '
          'audio, speed and quality menus ("Uit", "Automatisch", "Normaal") '
          'and the screen reader speaks the Dutch control names. '
          'OGUIConfig(strings: …) — the same keys in every OGPlayer SDK, and '
          'OGStrings.fromMap takes that shared map as-is.',
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
                'Localised chrome (nl)',
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
                // A fresh player per scenario: the film opens paused on its
                // poster (menus at hand), live starts playing.
                key: ValueKey(_mode),
                source: _source,
                uiConfig: _uiConfig,
                autoplay: _mode != 0,
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
                      labels: const ['On demand', 'Live DVR', 'Error overlay'],
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

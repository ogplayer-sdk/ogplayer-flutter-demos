import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_catalog.dart';
import 'theme.dart';

/// Test hook: `flutter run --dart-define=OG_DEMO=orientation` (or a
/// `--dart-define` in automation) jumps straight into a demo screen.
/// Mirrors Android's `og.demo` intent extra and iOS's `OG_DEMO` env var.
const _startDemo = String.fromEnvironment('OG_DEMO');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The launcher is a list of features — it has no business in landscape.
  // Demo routes widen this on entry and put it back on exit (see
  // [_DemoOrientation]), the same shape as the native iOS demos.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const OGPlayerDemosApp());
}

/// Orientation bracket around every demo route: any orientation while the
/// demo is up (rotation-driven fullscreen needs the activity to rotate),
/// portrait again once it is gone.
///
/// The ORDER matters against the plugin's orientation pins. A player view
/// captures the host's orientation right before it takes its pin, so the
/// widen must be written before the player mounts — `initState` of this
/// wrapper runs before any child builds. And the portrait restore must be
/// written after the player has released its pin (which puts the captured
/// value back) — `dispose` of this wrapper runs after its children's, and
/// platform messages are delivered in send order.
class _DemoOrientation extends StatefulWidget {
  const _DemoOrientation({required this.child});

  final Widget child;

  @override
  State<_DemoOrientation> createState() => _DemoOrientationState();
}

class _DemoOrientationState extends State<_DemoOrientation> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const []); // = the system's choice
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class OGPlayerDemosApp extends StatelessWidget {
  const OGPlayerDemosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final startDemo = demoForRoute(_startDemo);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: demoTheme(),
      home: startDemo?.builder != null
          ? _DemoOrientation(child: Builder(builder: startDemo!.builder!))
          : const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InkColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            const _Header(),
            const SizedBox(height: 4),
            for (final group in demoGroups) ...[
              _GroupHeader(group.header),
              for (final demo in group.demos) ...[
                _DemoRow(demo),
                const SizedBox(height: 5),
              ],
            ],
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'Unlicensed build — demos render the OGPlayer watermark.',
                style: TextStyle(color: InkColors.groupHeader, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 8),
            const Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'OG',
                  style: TextStyle(
                    color: InkColors.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'Player',
                  style: TextStyle(color: InkColors.description, fontSize: 17),
                ),
              ]),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: InkColors.tagBg,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                sdkVersion,
                style: TextStyle(color: InkColors.description, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Integration demos',
          style: TextStyle(
            color: InkColors.title,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every SDK capability, demonstrated end to end.',
          style: TextStyle(color: InkColors.description, fontSize: 12),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: InkColors.groupHeader,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  const _DemoRow(this.demo);

  final Demo demo;

  @override
  Widget build(BuildContext context) {
    final enabled = demo.builder != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: InkColors.rowSurface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          _DemoOrientation(child: demo.builder!(context)),
                    ),
                  )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: InkColors.rowBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: InkColors.iconTile,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(demo.icon, color: InkColors.accent, size: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              demo.title,
                              style: const TextStyle(
                                color: InkColors.title,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (demo.tag != null) _Chip(demo.tag!),
                          if (!enabled) _Chip(demo.pendingLabel),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        demo.description,
                        style: const TextStyle(
                          color: InkColors.description,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: InkColors.chevron, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: InkColors.tagBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: InkColors.description,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Rolling in-memory event log shown under the demo players — port of the
/// native demos' EventLog. Screens wire the OGPlayerView callbacks straight
/// into [EventLogState.add] (callbacks are view props in Flutter; there is
/// no listener object to attach).
class EventLogState extends ChangeNotifier {
  static const _maxEntries = 300;

  final List<String> entries = [];

  void add(String message) {
    final now = DateTime.now();
    String pad2(int v) => v.toString().padLeft(2, '0');
    final stamp = '${pad2(now.hour)}:${pad2(now.minute)}:${pad2(now.second)}'
        '.${now.millisecond.toString().padLeft(3, '0')}';
    entries.add('$stamp  $message');
    if (entries.length > _maxEntries) entries.removeAt(0);
    notifyListeners();
  }
}

/// Terminal-style auto-scrolling list of logged callbacks.
class EventLogView extends StatefulWidget {
  const EventLogView(this.log, {super.key});

  final EventLogState log;

  @override
  State<EventLogView> createState() => _EventLogViewState();
}

class _EventLogViewState extends State<EventLogView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.log.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.log.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101418),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.log.entries.length,
        itemBuilder: (context, index) => Text(
          widget.log.entries[index],
          style: const TextStyle(
            color: Color(0xFF9CCC65),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

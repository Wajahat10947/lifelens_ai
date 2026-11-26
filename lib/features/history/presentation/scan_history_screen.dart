
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../data/scan_history_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() =>
      _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScanHistoryService _historyService =
      ScanHistoryService();

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      _scansStream;

  @override
  void initState() {
    super.initState();
    _scansStream = _historyService.watchScans();
  }

  // Delete scan with confirmation
  Future<void> _deleteScan(String scanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: const Text(
          'This scan will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await _historyService.deleteScan(scanId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan deleted successfully'),
        ),
      );
    } catch (e) {
      debugPrint('Delete Error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete scan'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const purple = Color(0xFF8B5CF6);
    const cyan = Color(0xFF22D3EE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        centerTitle: true,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),

          child: StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _scansStream,

            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: purple,
                  ),
                );
              }

              // Error
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'History load nahi ho saki.',
                  ),
                );
              }

              final scans = snapshot.data?.docs ?? [];

              // Empty history
              if (scans.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 75,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No scans yet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan an object to see it here.',
                      ),
                    ],
                  ),
                );
              }

              // History list
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: scans.length,

                itemBuilder: (context, index) {
                  final doc = scans[index];
                  final data = doc.data();

                  final analysis =
                      data['analysis'] as String? ?? '';

                  final timestamp = data['createdAt'];

                  final DateTime? date =
                      timestamp is Timestamp
                          ? timestamp.toDate().toLocal()
                          : null;

                  final dateText = date == null
                      ? 'Saving date...'
                      : '${MaterialLocalizations.of(context).formatMediumDate(date)} • ${TimeOfDay.fromDateTime(date).format(context)}';

                  final preview = analysis
                      .replaceAll(
                        RegExp(r'[#*`>]'),
                        '',
                      )
                      .replaceAll('\n', ' ')
                      .trim();

                  return Card(
                    color: colors.surface,
                    margin: const EdgeInsets.only(
                      bottom: 14,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      side: BorderSide(
                        color: purple.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),

                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: purple.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.center_focus_strong,
                          color: cyan,
                        ),
                      ),

                      title: Text(
                        'AI Scan ${scans.length - index}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),

                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      childrenPadding:
                          const EdgeInsets.all(18),

                      children: [
                        Divider(
                          color: purple.withValues(
                            alpha: 0.25,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: MarkdownBody(
                            data: analysis,
                            selectable: true,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                _deleteScan(doc.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Delete Scan',
                              style: TextStyle(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

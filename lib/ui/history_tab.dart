import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/models/assessment_history.dart';
import 'package:orm_risk_assessment/services/data_service.dart';
import 'package:orm_risk_assessment/ui/history_detail_page.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final DataService _dataService = DataService();
  List<AssessmentHistory> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
    });

    final history = await _dataService.getAssessmentHistory();

    setState(() {
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history, size: 60, color: Color(0xFF777777)),
            SizedBox(height: 10),
            Text(
              'No history yet',
              style: TextStyle(color: Color(0xFFB8D4A8), fontSize: 23),
            ),
            SizedBox(height: 6),
            Text(
              'Save an assessment from the Risk Assessment tab to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _history[index];
          return _HistoryTile(
            history: item,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => HistoryDetailPage(history: item),
              ));
              // refresh in case user wants to see updates
              _loadHistory();
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AssessmentHistory history;
  final VoidCallback onTap;

  const _HistoryTile({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        history.createdAt.toLocal().toString().split('.').first;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4A6741)),
          color: const Color(0xFF0F2419),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFFB8D4A8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    history.mission.missionType.isNotEmpty
                        ? history.mission.missionType
                        : 'Untitled assessment',
                    style: const TextStyle(
                      color: Color(0xFFB8D4A8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilot: ${history.mission.pilotName} · Date: ${history.mission.missionTime}',
              style: const TextStyle(color: Color(0xFFD4E8C8)),
            ),
            const SizedBox(height: 6),
            Text(
              formattedDate,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 21),
            ),
          ],
        ),
      ),
    );
  }
}

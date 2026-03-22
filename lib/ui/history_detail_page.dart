import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/models/assessment_history.dart';

class HistoryDetailPage extends StatelessWidget {
  final AssessmentHistory history;

  const HistoryDetailPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final createdAt = history.createdAt.toLocal().toString().split('.').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Details'),
        backgroundColor: const Color(0xFF4A6741),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              history.mission.missionType.isNotEmpty
                  ? history.mission.missionType
                  : 'Untitled assessment',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8D4A8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved: $createdAt',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Mission & Crew'),
            _detailRow('Pilot', history.mission.pilotName),
            _detailRow('Pilot Code', history.mission.pilotCode),
            if (history.mission.secondPilotName.isNotEmpty ||
                history.mission.secondPilotCode.isNotEmpty) ...[
              _detailRow('Second Pilot', history.mission.secondPilotName),
              _detailRow('Second Pilot Code', history.mission.secondPilotCode),
            ],
            _detailRow('Mechanic', history.mission.mechanicName),
            _detailRow('Mission Date', history.mission.missionTime),
            _detailRow('Mission Type', history.mission.missionType),
            const SizedBox(height: 16),
            _sectionTitle('Risk Items'),
            ...history.entries.map((entry) => _riskEntryCard(entry)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB8D4A8),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFFB8D4A8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(color: Color(0xFFD4E8C8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskEntryCard(dynamic entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4A6741)),
        color: const Color(0xFF0F2419),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Category', entry.category),
          _detailRow('Title', entry.title),
          _detailRow('Description', entry.description),
          _detailRow('Likelihood', entry.likelihood.toString()),
          _detailRow('Severity', entry.severity.toString()),
          _detailRow('Deduction', entry.deduction.toString()),
          _detailRow('Risk Value', entry.riskValue.toString()),
          _detailRow('Residual Risk', entry.finalRiskValue.toString()),
        ],
      ),
    );
  }
}

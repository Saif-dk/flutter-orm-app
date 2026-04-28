import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/models/assessment_history.dart';

// ─── colour tokens (mirrors launch_page) ──────────────────────────────────────
const _cBackground = Color(0xFF090C1A);
const _cSurface = Color.fromARGB(255, 14, 40, 28);
const _cBorder = Color.fromARGB(255, 30, 107, 57);
const _cBorderBright = Color.fromARGB(255, 45, 201, 89);
const _cAccent = Color.fromARGB(255, 61, 232, 121);
const _cTextPrimary = Color(0xFFDDE3FF);
const _cTextSub = Color(0xFF6677CC);
const _cLetterLit = Color.fromARGB(255, 79, 255, 146);
const _cLetterGlow = Color.fromARGB(255, 170, 255, 194);
const _cGreenFg = Color(0xFFBBE0B0);

class HistoryDetailPage extends StatelessWidget {
  final AssessmentHistory history;

  const HistoryDetailPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final createdAt = history.createdAt.toLocal().toString().split('.').first;

    return Scaffold(
      backgroundColor: _cBackground,
      appBar: AppBar(
        title: const Text(
          'ASSESSMENT DETAILS',
          style: TextStyle(
            color: _cLetterLit,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            fontSize: 19,
          ),
        ),
        backgroundColor: _cSurface,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cLetterLit),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(height: 1.5, color: _cBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cSurface,
                border: Border(
                  left: BorderSide(color: _cLetterLit, width: 3),
                  top: BorderSide(color: _cBorder),
                  right: BorderSide(color: _cBorder),
                  bottom: BorderSide(color: _cBorder),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cAccent.withOpacity(0.06),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.mission.missionType.isNotEmpty
                        ? history.mission.missionType.toUpperCase()
                        : 'UNTITLED ASSESSMENT',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: _cLetterLit,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('▸ ',
                          style: TextStyle(color: _cAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        'SAVED: $createdAt',
                        style: const TextStyle(
                          color: _cTextSub,
                          fontSize: 14,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Mission & Crew ─────────────────────────────────────────────
            _sectionTitle('MISSION & CREW'),
            const SizedBox(height: 8),
            _infoCard(
              children: [
                _detailRow('Pilot', history.mission.pilotName),
                _detailRow('Pilot Code', history.mission.pilotCode),
                if (history.mission.secondPilotName.isNotEmpty ||
                    history.mission.secondPilotCode.isNotEmpty) ...[
                  _detailRow('Second Pilot', history.mission.secondPilotName),
                  _detailRow(
                      'Second Pilot Code', history.mission.secondPilotCode),
                ],
                _detailRow('Mechanic', history.mission.mechanicName),
                _detailRow('Mission Date', history.mission.missionTime),
                _detailRow('Mission Type', history.mission.missionType),
              ],
            ),

            const SizedBox(height: 16),

            // ── Risk Items ─────────────────────────────────────────────────
            _sectionTitle('RISK ITEMS'),
            const SizedBox(height: 8),
            ...history.entries.map((entry) => _riskEntryCard(entry)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: _cLetterLit),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _cLetterLit,
              letterSpacing: 3,
            ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: _cBorder),
        ),
      ],
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cSurface,
        border: Border.all(color: _cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('▸ ', style: TextStyle(color: _cAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          SizedBox(
            width: 120,
              child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: _cLetterLit,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                color: _cTextPrimary,
                fontSize: 16,
                letterSpacing: 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskEntryCard(dynamic entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF060E18),
        border: Border.all(color: _cBorder),
        boxShadow: [
          BoxShadow(
            color: _cAccent.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: _cSurface,
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: _cAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.title.isNotEmpty
                        ? entry.title.toUpperCase()
                        : 'RISK ITEM',
                    style: const TextStyle(
                      color: _cLetterGlow,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Category', entry.category),
                _detailRow('Description', entry.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                        child: _statBadge(
                            'LIKELIHOOD', entry.likelihood.toString())),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _statBadge('SEVERITY', entry.severity.toString())),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _statBadge(
                            'DEDUCTION', entry.deduction.toString())),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _statBadge(
                            'RISK VALUE', entry.riskValue.toString(),
                            highlight: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _statBadge(
                            'RESIDUAL RISK', entry.finalRiskValue.toString(),
                            highlight: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? _cAccent.withOpacity(0.12)
            : const Color.fromARGB(255, 9, 26, 15),
        border: Border.all(
          color: highlight ? _cBorderBright : _cBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? _cLetterLit : _cTextSub,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: highlight ? _cLetterGlow : _cTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

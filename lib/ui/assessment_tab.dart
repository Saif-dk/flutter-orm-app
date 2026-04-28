import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orm_risk_assessment/models/assessment_history.dart';
import 'package:orm_risk_assessment/models/risk_entry.dart';
import 'package:orm_risk_assessment/models/mission_details.dart';
import 'package:orm_risk_assessment/services/data_service.dart';
import 'package:orm_risk_assessment/services/export_service.dart';

// ─── colour tokens (mirrors launch_page) ─────────────────────────────────────
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

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const List<Map<String, dynamic>> LIKELIHOOD_OPTIONS = [
  {'v': 1, 'label': 'Very improbable'},
  {'v': 2, 'label': 'Improbable'},
  {'v': 3, 'label': 'Remote'},
  {'v': 4, 'label': 'Probable'},
  {'v': 5, 'label': 'Frequent'},
];

const List<Map<String, dynamic>> SEVERITY_OPTIONS = [
  {'v': 1, 'label': 'Negligible'},
  {'v': 2, 'label': 'Minor'},
  {'v': 3, 'label': 'Major'},
  {'v': 4, 'label': 'Critical'},
  {'v': 5, 'label': 'Catastrophic'},
];

const List<String> CATEGORIES = [
  'Human Factors',
  'ENVIRONMENT',
  'Leadership & Supervision',
  'Interface (Human-Machine)',
  'Communications',
  'Operations / Mission',
  'Planning',
  'Task Proficiency and Currency',
  'Equipment',
  'Regulations / Risk Decisions',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
String riskCategoryFrom(double score) {
  if (score >= 21 && score <= 25) return 'Extreme risk';
  if (score >= 15 && score <= 20) return 'Very high risk';
  if (score >= 10 && score <= 14) return 'High risk';
  if (score >= 5 && score <= 9) return 'Moderate risk';
  if (score >= 1 && score <= 4) return 'Low risk';
  return '-';
}

Color colorFromCategory(String category) {
  switch (category) {
    case 'Low risk':
      return const Color(0xFF4CAF50);
    case 'Moderate risk':
      return const Color(0xFFFFC107);
    case 'High risk':
      return const Color(0xFFFF9800);
    case 'Very high risk':
      return const Color(0xFFF44336);
    case 'Extreme risk':
      return const Color(0xFF323232);
    default:
      return Colors.white;
  }
}

Color textColorForCategory(String category) =>
    (category == 'Extreme risk' || category == 'Very high risk')
        ? Colors.white
        : Colors.black;

String mapCategoryToStorageKey(String cat) {
  const map = {
    'Planning': 'PLANNING',
    'Interface (Human-Machine)': 'INTERFACE (HUMAN-MACHINE)',
    'Leadership & Supervision': 'LEADERSHIP & SUPERVISION',
    'Human Factors': 'HUMAN FACTORS',
    'Communications': 'COMMUNICATIONS',
    'Operations / Mission': 'OPERATIONS / MISSION',
    'Task Proficiency and Currency': 'TASK PROFICIENCY AND CURRENCY',
    'Equipment': 'EQUIPMENT',
    'Regulations / Risk Decisions': 'REGULATIONS / RISK DECISIONS',
    'ENVIRONMENT': 'ENVIRONMENT',
  };
  return map[cat] ?? cat.toUpperCase();
}

// ---------------------------------------------------------------------------
// Per-row in-memory model
// ---------------------------------------------------------------------------
class _RiskRow {
  String id;
  String category;
  String title;
  int likelihood;
  int severity;
  String description;
  double deduction;
  List<String> choices;

  _RiskRow({
    required this.id,
    required this.category,
    this.title = '',
    this.likelihood = 1,
    this.severity = 1,
    this.description = '',
    this.deduction = 0,
    this.choices = const [],
  });

  double get riskValue => (likelihood * severity).toDouble();
  double get finalRiskValue => riskValue - deduction;

  RiskEntry toRiskEntry() => RiskEntry(
        id: id,
        category: category,
        title: title,
        description: description,
        likelihood: likelihood,
        severity: severity,
        deduction: deduction,
        riskValue: riskValue,
        finalRiskValue: finalRiskValue,
      );

  static _RiskRow fromRiskEntry(RiskEntry e) => _RiskRow(
        id: e.id,
        category: e.category,
        title: e.title,
        likelihood: e.likelihood,
        severity: e.severity,
        description: e.description,
        deduction: e.deduction.toDouble(),
      );
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------
class AssessmentTab extends StatefulWidget {
  const AssessmentTab({super.key});
  @override
  State<AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends State<AssessmentTab> {
  final DataService _dataService = DataService();
  late MissionDetails _mission;
  final Map<String, List<_RiskRow>> _rows = {};
  Map<String, dynamic> _hazardExamples = {};
  final Map<String, bool> _showExampleDropdown = {};
  List<String> _missingFields = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    for (final cat in CATEGORIES) {
      _rows[cat] = [];
      _showExampleDropdown[cat] = false;
    }
    _clearDataAndLoad();
  }

  Future<void> _clearDataAndLoad() async {
    await _dataService.saveRiskEntries([]);
    await _dataService.saveMissionDetails(MissionDetails(
      pilotName: '',
      pilotCode: '',
      secondPilotName: '',
      secondPilotCode: '',
      mechanicName: '',
      missionType: '',
      missionTime: '',
    ));
    _loadData();
  }

  Future<void> _loadData() async {
    _mission = await _dataService.getMissionDetails();
    _hazardExamples = await _dataService.getCustomHazardExamples();
    final entries = await _dataService.getRiskEntries();
    for (final cat in CATEGORIES) {
      _rows[cat] = [];
    }
    for (final e in entries) {
      final cat = _rows.containsKey(e.category) ? e.category : CATEGORIES.first;
      _rows[cat]!.add(_RiskRow.fromRiskEntry(e));
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    final all = <RiskEntry>[];
    for (final cat in CATEGORIES) {
      all.addAll(_rows[cat]!.map((r) => r.toRiskEntry()));
    }
    await _dataService.saveRiskEntries(all);
  }

  Future<void> _saveMission() async =>
      await _dataService.saveMissionDetails(_mission);

  double? get _ormScore {
    double? max;
    for (final cat in CATEGORIES) {
      for (final r in _rows[cat]!) {
        final v = r.finalRiskValue;
        if (max == null || v > max) max = v;
      }
    }
    return max;
  }

  List<Map<String, dynamic>> _examplesFor(String cat) {
    final key = mapCategoryToStorageKey(cat);
    final raw = _hazardExamples[key];
    if (raw is List) {
      return raw.map((item) {
        if (item is Map)
          return {
            'name': item['name'] ?? '',
            'choices': item['choices'] is List ? item['choices'] : []
          };
        return {'name': item.toString(), 'choices': []};
      }).toList();
    }
    return [];
  }

  void _addRisk(String cat,
      {String title = '', List<String> choices = const []}) {
    final row = _RiskRow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: cat,
      title: title,
      choices: choices,
    );
    setState(() {
      _rows[cat]!.add(row);
      _showExampleDropdown[cat] = false;
    });
    _save();
  }

  void _removeRisk(String cat, String id) {
    _riskTitleControllers.remove(id)?.dispose();
    _riskDescControllers.remove(id)?.dispose();
    _riskDedControllers.remove(id)?.dispose();
    setState(() {
      _rows[cat]!.removeWhere((r) => r.id == id);
    });
    _save();
  }

  bool _validate() {
    final missing = <String>[];
    if (_mission.pilotName.trim().isEmpty) missing.add('Pilot Name');
    if (_mission.pilotCode.trim().isEmpty) missing.add('Pilot Code');
    if (_mission.missionTime.trim().isEmpty) missing.add('Mission Date');
    if (_mission.missionType.trim().isEmpty) missing.add('Mission Type');
    setState(() {
      _missingFields = missing;
    });
    return missing.isEmpty;
  }

  bool _isFieldMissing(String label) => _missingFields.contains(label);

  Future<void> _exportToExcel() async {
    if (!_validate()) {
      _snackbar('Please complete required fields before exporting', Colors.red);
      return;
    }
    await _save();
    await _saveMission();
    try {
      await ExportService.exportExcel(
          mission: _mission, rowsByCategory: _rows, ormScore: _ormScore);
      _snackbar('Excel file saved successfully', Colors.green);
    } catch (e) {
      _snackbar('Excel export failed: $e', Colors.red);
    }
  }

  Future<void> _exportToCSV() async {
    await _save();
    try {
      await ExportService.exportCsv(mission: _mission, rowsByCategory: _rows);
      _snackbar('CSV file saved successfully', Colors.green);
    } catch (e) {
      _snackbar('CSV export failed: $e', Colors.red);
    }
  }

  Future<void> _exportToPDF() async {
    if (!_validate()) {
      _snackbar('Please complete required fields before exporting', Colors.red);
      return;
    }
    await _save();
    await _saveMission();
    try {
      await ExportService.exportPdf(
          mission: _mission, rowsByCategory: _rows, ormScore: _ormScore);
      _snackbar('PDF file saved successfully', Colors.green);
    } catch (e) {
      _snackbar('PDF export failed: $e', Colors.red);
    }
  }

  Future<void> _saveToHistory() async {
    if (!_validate()) {
      _snackbar('Please complete required fields before saving', Colors.red);
      return;
    }
    await _save();
    await _saveMission();
    final entries = <RiskEntry>[];
    for (final cat in CATEGORIES) {
      entries.addAll(_rows[cat]!.map((r) => r.toRiskEntry()));
    }
    final item = AssessmentHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      mission: _mission,
      entries: entries,
    );
    await _dataService.addToAssessmentHistory(item);
    _snackbar('Saved to history', Colors.green);
  }

  void _snackbar(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(letterSpacing: 1)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: _cBackground,
        child: const Center(
          child: CircularProgressIndicator(color: _cLetterLit),
        ),
      );
    }

    return Container(
      color: _cBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_missingFields.isNotEmpty) _buildValidationBanner(),
            _buildMissionSection(),
            const SizedBox(height: 16),
            for (final cat in CATEGORIES) ...[
              _buildCategorySection(cat),
              const SizedBox(height: 16),
            ],
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildValidationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0505),
        border: Border(
          left: const BorderSide(color: Color(0xFFFF4040), width: 3),
          top: BorderSide(color: const Color(0xFF8B1010)),
          right: BorderSide(color: const Color(0xFF8B1010)),
          bottom: BorderSide(color: const Color(0xFF8B1010)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFFFB74D), size: 18),
              SizedBox(width: 8),
                Text(
                'FORM INCOMPLETE',
                style: TextStyle(
                  color: Color(0xFFFFB74D),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Please fill in the following required fields:',
            style:
                TextStyle(color: _cTextSub, fontSize: 8, letterSpacing: 0.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final f in _missingFields)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                    const Text('▸ ',
                      style: TextStyle(color: Color(0xFFFF6060), fontSize: 6, fontWeight: FontWeight.bold)),
                    Text(f,
                      style: const TextStyle(
                        color: Color(0xFFFFCDD2), fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mission & Crew Information section
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMissionSection() {
    return _sectionContainer(
      title: 'MISSION & CREW INFORMATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _missionTextField(
                      key: 'pilotName',
                      value: _mission.pilotName,
                      placeholder: 'Pilot Name',
                      required: true,
                      missingLabel: 'Pilot Name',
                      capitalize: true,
                      onChanged: (v) => setState(
                          () => _mission = _mission.copyWith(pilotName: v)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _missionTextField(
                      key: 'pilotCode',
                      value: _mission.pilotCode,
                      placeholder: 'Pilot Code',
                      required: true,
                      missingLabel: 'Pilot Code',
                      uppercase: true,
                      onChanged: (v) => setState(
                          () => _mission = _mission.copyWith(pilotCode: v)))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _missionTextField(
                      key: 'secondPilotName',
                      value: _mission.secondPilotName,
                      placeholder: 'Second Pilot Name',
                      capitalize: true,
                      onChanged: (v) => setState(() =>
                          _mission = _mission.copyWith(secondPilotName: v)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _missionTextField(
                      key: 'secondPilotCode',
                      value: _mission.secondPilotCode,
                      placeholder: 'Second Pilot Code',
                      uppercase: true,
                      onChanged: (v) => setState(() =>
                          _mission = _mission.copyWith(secondPilotCode: v)))),
            ],
          ),
          const SizedBox(height: 10),
          _missionTextField(
              key: 'mechanicName',
              value: _mission.mechanicName,
              placeholder: 'Mechanic Name',
              capitalize: true,
              onChanged: (v) => setState(
                  () => _mission = _mission.copyWith(mechanicName: v))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _missionDateField()),
              const SizedBox(width: 10),
              Expanded(
                  child: _missionTextField(
                      key: 'missionType',
                      value: _mission.missionType,
                      placeholder: 'Mission Type',
                      required: true,
                      missingLabel: 'Mission Type',
                      capitalize: true,
                      onChanged: (v) => setState(
                          () => _mission = _mission.copyWith(missionType: v)))),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-category risk section
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategorySection(String cat) {
    final examples = _examplesFor(cat);
    final showDropdown = _showExampleDropdown[cat] ?? false;

    return _sectionContainer(
      title: cat.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in _rows[cat]!) ...[
            _buildRiskRow(cat, row),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (examples.isNotEmpty)
                _actionButton(
                    label: 'HAZARD',
                    color: _cSurface,
                    textColor: _cGreenFg,
                    borderColor: _cBorder,
                    onPressed: () => setState(
                        () => _showExampleDropdown[cat] = !showDropdown)),
              const SizedBox(width: 10),
              _actionButton(
                  label: '+ ADD RISK',
                  color: _cAccent.withOpacity(0.15),
                  textColor: _cLetterLit,
                  borderColor: _cBorderBright,
                  onPressed: () => _addRisk(cat)),
            ],
          ),
          if (showDropdown && examples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildExampleDropdown(cat, examples),
            ),
        ],
      ),
    );
  }

  Widget _buildExampleDropdown(
      String cat, List<Map<String, dynamic>> examples) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 9, 26, 15),
        border: Border.all(color: _cBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: null,
          dropdownColor: const Color(0xFF0A1A10),
            hint: const Text('Select a hazard…',
              style: TextStyle(color: Color(0xFF4A6060), fontSize: 9, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.arrow_drop_down, color: _cLetterLit),
          style: const TextStyle(color: _cTextPrimary, fontSize: 10, fontWeight: FontWeight.bold),
          items: examples.map((ex) {
            final name = ex['name'] as String;
            return DropdownMenuItem<String>(value: name, child: Text(name));
          }).toList(),
          onChanged: (name) {
            if (name == null) return;
            final ex =
                examples.firstWhere((e) => e['name'] == name, orElse: () => {});
            final choices = (ex['choices'] as List?)?.cast<String>() ?? [];
            _addRisk(cat, title: name, choices: choices);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Single risk row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRiskRow(String cat, _RiskRow row) {
    final catLabel = riskCategoryFrom(row.riskValue);
    final finalCatLabel = riskCategoryFrom(row.finalRiskValue);
    final riskPillBg = colorFromCategory(catLabel);
    final riskPillTxt = textColorForCategory(catLabel);
    final finalPillBg = colorFromCategory(finalCatLabel);
    final finalPillTxt = textColorForCategory(finalCatLabel);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060E18),
        border: Border.all(color: _cBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _riskTitleCtrl(row.id, row.title),
            style: const TextStyle(color: _cTextPrimary, fontSize: 10, fontWeight: FontWeight.bold),
            decoration: _rowInputDecoration('Risk Title'),
            inputFormatters: [_CapitalizeFirstFormatter()],
            onChanged: (v) {
              row.title = v;
              _rebuildAndSave();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _likelihoodDropdown(row)),
              const SizedBox(width: 10),
              Expanded(child: _severityDropdown(row)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: row.choices.isNotEmpty
                    ? _descriptionDropdown(row)
                    : _descriptionTextField(row),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _riskDedCtrl(
                      row.id,
                      row.deduction == 0
                          ? ''
                          : row.deduction.toStringAsFixed(0)),
                  style: const TextStyle(color: _cTextPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                  decoration: _rowInputDecoration('Deduction'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  onChanged: (v) {
                    row.deduction = double.tryParse(v) ?? 0;
                    _rebuildAndSave();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _riskPill('Risk: ${row.riskValue.toInt()}', riskPillBg,
                      riskPillTxt)),
              const SizedBox(width: 8),
              Expanded(
                  child: _riskPill('Residual: ${row.finalRiskValue.toInt()}',
                      finalPillBg, finalPillTxt)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _removeRisk(cat, row.id);
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0505),
                    border: Border.all(color: const Color(0xFF8B1010)),
                  ),
                  child: const Icon(Icons.close,
                      color: Color(0xFFFF4444), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _likelihoodDropdown(_RiskRow row) => _buildScaleDropdown(
      value: row.likelihood,
      options: LIKELIHOOD_OPTIONS,
      onChanged: (v) {
        row.likelihood = v;
        _rebuildAndSave();
      });
  Widget _severityDropdown(_RiskRow row) => _buildScaleDropdown(
      value: row.severity,
      options: SEVERITY_OPTIONS,
      onChanged: (v) {
        row.severity = v;
        _rebuildAndSave();
      });

  Widget _buildScaleDropdown(
      {required int value,
      required List<Map<String, dynamic>> options,
      required void Function(int) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 9, 26, 15),
        border: Border.all(color: _cBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF0A1A10),
          icon: const Icon(Icons.arrow_drop_down, color: _cLetterLit),
          style: const TextStyle(color: _cTextPrimary, fontSize: 9, fontWeight: FontWeight.bold),
          items: options.map((o) {
            final v = o['v'] as int;
            return DropdownMenuItem<int>(
                value: v, child: Text('$v — ${o['label']}'));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _descriptionTextField(_RiskRow row) => TextField(
        controller: _riskDescCtrl(row.id, row.description),
        style: const TextStyle(color: _cTextPrimary, fontSize: 10, fontWeight: FontWeight.bold),
        decoration: _rowInputDecoration('Description'),
        inputFormatters: [_CapitalizeFirstFormatter()],
        onChanged: (v) {
          row.description = v;
          _rebuildAndSave();
        },
      );

  Widget _descriptionDropdown(_RiskRow row) => Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 9, 26, 15),
          border: Border.all(color: _cBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: row.description.isEmpty ? null : row.description,
            dropdownColor: const Color(0xFF0A1A10),
            hint: const Text('Select a choice…',
              style: TextStyle(color: Color(0xFF4A6060), fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.arrow_drop_down, color: _cLetterLit),
            style: const TextStyle(color: _cTextPrimary, fontSize: 9, fontWeight: FontWeight.bold),
            items: row.choices
                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                row.description = v;
                _rebuildAndSave();
              }
            },
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Results section
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildResultsSection() {
    final score = _ormScore;
    final catLabel = score != null ? riskCategoryFrom(score) : '-';
    final bg = score != null ? colorFromCategory(catLabel) : Colors.white;
    final txt = score != null ? textColorForCategory(catLabel) : Colors.black;
    final scoreText = score != null ? score.toInt().toString() : '-';

    return _sectionContainer(
      title: 'ORM RESULTS & EXPORT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _badge('ORM RISK: $scoreText', bg, txt)),
              const SizedBox(width: 10),
              Expanded(child: _badge('CATEGORY: $catLabel', bg, txt)),
            ],
          ),
          const SizedBox(height: 16),
          _hudLabel('EXPORT OPTIONS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _exportButton(
                      label: '💾 Excel',
                      bg: _cSurface,
                      txtColor: _cLetterLit,
                      borderColor: _cBorderBright,
                      onPressed: _exportToExcel)),
              const SizedBox(width: 8),
              Expanded(
                  child: _exportButton(
                      label: '📝 CSV',
                      bg: _cSurface,
                      txtColor: _cGreenFg,
                      borderColor: _cBorder,
                      onPressed: _exportToCSV)),
              const SizedBox(width: 8),
              Expanded(
                  child: _exportButton(
                      label: '📄 PDF',
                      bg: const Color(0xFF1A1000),
                      txtColor: const Color(0xFFFFE8C8),
                      borderColor: const Color(0xFF8B5A00),
                      onPressed: _exportToPDF)),
            ],
          ),
          const SizedBox(height: 10),
          _exportButton(
              label: '📌 SAVE TO HISTORY',
              bg: _cAccent.withOpacity(0.15),
              txtColor: _cLetterLit,
              borderColor: _cBorderBright,
              onPressed: _saveToHistory),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, TextEditingController> _missionControllers = {};
  final Map<String, TextEditingController> _riskTitleControllers = {};
  final Map<String, TextEditingController> _riskDescControllers = {};
  final Map<String, TextEditingController> _riskDedControllers = {};

  TextEditingController _missionCtrl(String key, String initialValue) {
    if (!_missionControllers.containsKey(key))
      _missionControllers[key] = TextEditingController(text: initialValue);
    return _missionControllers[key]!;
  }

  TextEditingController _riskTitleCtrl(String id, String initialValue) {
    if (!_riskTitleControllers.containsKey(id))
      _riskTitleControllers[id] = TextEditingController(text: initialValue);
    return _riskTitleControllers[id]!;
  }

  TextEditingController _riskDescCtrl(String id, String initialValue) {
    if (!_riskDescControllers.containsKey(id))
      _riskDescControllers[id] = TextEditingController(text: initialValue);
    return _riskDescControllers[id]!;
  }

  TextEditingController _riskDedCtrl(String id, String initialValue) {
    if (!_riskDedControllers.containsKey(id))
      _riskDedControllers[id] = TextEditingController(text: initialValue);
    return _riskDedControllers[id]!;
  }

  @override
  void dispose() {
    for (final c in _missionControllers.values) c.dispose();
    for (final c in _riskTitleControllers.values) c.dispose();
    for (final c in _riskDescControllers.values) c.dispose();
    for (final c in _riskDedControllers.values) c.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Mission field builders
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _missionTextField({
    required String key,
    required String value,
    required String placeholder,
    required void Function(String) onChanged,
    bool required = false,
    String missingLabel = '',
    bool capitalize = false,
    bool uppercase = false,
  }) {
    final isMissing = required && _isFieldMissing(missingLabel);
    final ctrl = _missionCtrl(key, value);
    if (ctrl.text != value) ctrl.text = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          style: const TextStyle(color: _cTextPrimary, fontSize: 10, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
                color: isMissing
                    ? const Color(0xFF8B3030)
                    : const Color(0xFF4A6060),
                fontSize: 9, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: isMissing
                ? const Color(0xFF1A0505)
                : const Color.fromARGB(255, 9, 26, 15),
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: isMissing ? const Color(0xFF8B1010) : _cBorder),
                borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: isMissing ? const Color(0xFF8B1010) : _cBorder),
                borderRadius: BorderRadius.zero),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _cLetterLit, width: 2),
                borderRadius: BorderRadius.zero),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            if (uppercase) _UpperCaseFormatter(),
            if (capitalize) _CapitalizeFirstFormatter(),
          ],
          onChanged: (v) {
            onChanged(v);
            _saveMission();
          },
        ),
        if (required)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '* Required',
              style: TextStyle(
                color: isMissing
                    ? const Color(0xFFFF6060)
                    : const Color(0xFF3A5A4A),
                fontSize: 6,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _missionDateField() {
    final isMissing = _isFieldMissing('Mission Date');
    final ctrl = _missionCtrl('missionTime', _mission.missionTime);
    if (ctrl.text != _mission.missionTime) ctrl.text = _mission.missionTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _mission.missionTime.isNotEmpty
                  ? DateTime.tryParse(_mission.missionTime) ?? DateTime.now()
                  : DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (ctx, child) =>
                  Theme(data: Theme.of(ctx), child: child ?? const SizedBox()),
            );
            if (picked != null) {
              final iso = picked.toIso8601String().split('T').first;
              setState(() {
                _mission = _mission.copyWith(missionTime: iso);
              });
              _missionCtrl('missionTime', iso).text = iso;
              _saveMission();
            }
          },
            child: AbsorbPointer(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: _cTextPrimary, fontSize: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                hintStyle: TextStyle(
                    color: isMissing
                        ? const Color(0xFF8B3030)
                        : const Color(0xFF4A6060),
                    fontSize: 9, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: isMissing
                    ? const Color(0xFF1A0505)
                    : const Color.fromARGB(255, 9, 26, 15),
                border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isMissing ? const Color(0xFF8B1010) : _cBorder),
                    borderRadius: BorderRadius.zero),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isMissing ? const Color(0xFF8B1010) : _cBorder),
                    borderRadius: BorderRadius.zero),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _cLetterLit, width: 2),
                    borderRadius: BorderRadius.zero),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                prefixIcon: const Icon(Icons.calendar_today,
                    color: Color(0xFF4A7060), size: 16),
              ),
              readOnly: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '📅 * Required',
            style: TextStyle(
              color:
                  isMissing ? const Color(0xFFFF6060) : const Color(0xFF3A5A4A),
              fontSize: 6,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Small builders / helpers
  // ═══════════════════════════════════════════════════════════════════════════
  void _rebuildAndSave() {
    setState(() {});
    _save();
  }

  /// Section container with HUD-style header
  Widget _sectionContainer({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cSurface,
        border: Border.all(color: _cBorder),
        boxShadow: [
          BoxShadow(color: _cAccent.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _cAccent.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: _cBorder)),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 14, color: _cLetterLit),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _cLetterLit,
                    fontWeight: FontWeight.w800,
                    fontSize: 7,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  InputDecoration _rowInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4A6060), fontSize: 9, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: const Color.fromARGB(255, 9, 26, 15),
        border: const OutlineInputBorder(
            borderSide: BorderSide(color: _cBorder),
            borderRadius: BorderRadius.zero),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _cBorder),
            borderRadius: BorderRadius.zero),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _cLetterLit, width: 2),
            borderRadius: BorderRadius.zero),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

  Widget _riskPill(String text, Color bg, Color txtColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: bg, border: Border.all(color: bg.withOpacity(0.6))),
        child: Text(text,
          style: TextStyle(
            color: txtColor,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
          textAlign: TextAlign.center),
      );

  Widget _badge(String text, Color bg, Color txtColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: _cBorderBright.withOpacity(0.5))),
        child: Text(text,
          style: TextStyle(
            color: txtColor,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1)),
      );

  Widget _hudLabel(String text) => Row(
        children: [
            const Text('▸ ', style: TextStyle(color: _cAccent, fontSize: 6, fontWeight: FontWeight.bold)),
            Text(text,
              style: const TextStyle(
                color: _cTextSub,
                fontSize: 6,
                letterSpacing: 2,
                fontWeight: FontWeight.w700)),
        ],
      );

  Widget _actionButton(
          {required String label,
          required Color color,
          required Color textColor,
          required Color borderColor,
          required VoidCallback onPressed}) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
              color: color, border: Border.all(color: borderColor)),
            child: Text(label,
              style: TextStyle(
                color: textColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        ),
      );

  Widget _exportButton(
          {required String label,
          required Color bg,
          required Color txtColor,
          required Color borderColor,
          required Future<void> Function() onPressed}) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration:
              BoxDecoration(color: bg, border: Border.all(color: borderColor)),
          child: Center(
                child: Text(label,
                  style: TextStyle(
                    color: txtColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1))),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TextInputFormatters
// ─────────────────────────────────────────────────────────────────────────────
class _CapitalizeFirstFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final capitalized =
        newValue.text[0].toUpperCase() + newValue.text.substring(1);
    return newValue.copyWith(text: capitalized);
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

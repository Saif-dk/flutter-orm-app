import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orm_risk_assessment/models/risk_entry.dart';
import 'package:orm_risk_assessment/models/mission_details.dart';
import 'package:orm_risk_assessment/services/data_service.dart';
import 'package:orm_risk_assessment/services/export_service.dart';

// ---------------------------------------------------------------------------
// Constants – mirror the HTML exactly
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
  'Planning',
  'Interface (Human-Machine)',
  'Leadership & Supervision',
  'Human Factors',
  'Communications',
  'Operations / Mission',
  'Task Proficiency and Currency',
  'Equipment',
  'Regulations / Risk Decisions',
  'ENVIRONMENT',
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
      return const Color(0xFF4CAF50); // green
    case 'Moderate risk':
      return const Color(0xFFFFC107); // yellow
    case 'High risk':
      return const Color(0xFFFF9800); // orange
    case 'Very high risk':
      return const Color(0xFFF44336); // red
    case 'Extreme risk':
      return const Color(0xFF323232); // near-black
    default:
      return Colors.white;
  }
}

Color textColorForCategory(String category) {
  return (category == 'Extreme risk' || category == 'Very high risk')
      ? Colors.white
      : Colors.black;
}

/// Map assessment category names → the keys used in DataService storage
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
// Per-row in-memory model (not persisted individually – the whole list is)
// ---------------------------------------------------------------------------
class _RiskRow {
  String id;
  String category;
  String title;
  int likelihood;
  int severity;
  String description;
  double deduction;

  // choices list – if non-empty the description field becomes a dropdown
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
  // ─── data ───────────────────────────────────────────────────────────────
  final DataService _dataService = DataService();
  late MissionDetails _mission;
  // rows grouped by category  { "Planning": [row, …], … }
  final Map<String, List<_RiskRow>> _rows = {};
  // example lists per category { "Planning": [ {name, choices}, … ], … }
  Map<String, dynamic> _hazardExamples = {};
  // "Use Example" dropdown visibility per category
  final Map<String, bool> _showExampleDropdown = {};

  // ─── validation ─────────────────────────────────────────────────────────
  List<String> _missingFields = [];

  // ─── loading ────────────────────────────────────────────────────────────
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

  // ─── data loading ───────────────────────────────────────────────────────
  Future<void> _clearDataAndLoad() async {
    // Clear all stored data to start with empty form
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

    // Now load the cleared data
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

  // ─── persist ────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final all = <RiskEntry>[];
    for (final cat in CATEGORIES) {
      all.addAll(_rows[cat]!.map((r) => r.toRiskEntry()));
    }
    await _dataService.saveRiskEntries(all);
  }

  Future<void> _saveMission() async {
    await _dataService.saveMissionDetails(_mission);
  }

  // ─── ORM summary (max of all finalRiskValue) ───────────────────────────
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

  // ─── examples helpers ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _examplesFor(String cat) {
    final key = mapCategoryToStorageKey(cat);
    final raw = _hazardExamples[key];
    if (raw is List) {
      return raw.map((item) {
        if (item is Map) {
          return {
            'name': item['name'] ?? '',
            'choices': item['choices'] is List ? item['choices'] : [],
          };
        }
        return {'name': item.toString(), 'choices': []};
      }).toList();
    }
    return [];
  }

  // ─── add / remove ───────────────────────────────────────────────────────
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
    // Dispose controllers for this row before removing
    _riskTitleControllers.remove(id)?.dispose();
    _riskDescControllers.remove(id)?.dispose();
    _riskDedControllers.remove(id)?.dispose();

    setState(() {
      _rows[cat]!.removeWhere((r) => r.id == id);
    });
    _save();
  }

  // ─── validation ─────────────────────────────────────────────────────────
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

  // ─── exports ────────────────────────────────────────────────────────────
  Future<void> _exportToExcel() async {
    if (!_validate()) {
      _snackbar('Please complete required fields before exporting', Colors.red);
      return;
    }

    await _save();
    await _saveMission();

    try {
      await ExportService.exportExcel(
        mission: _mission,
        rowsByCategory: _rows,
        ormScore: _ormScore,
      );
      _snackbar('Excel file saved successfully', Colors.green);
    } catch (e) {
      _snackbar('Excel export failed: $e', Colors.red);
    }
  }

  Future<void> _exportToCSV() async {
    await _save();

    try {
      await ExportService.exportCsv(
        mission: _mission,
        rowsByCategory: _rows,
      );
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
        mission: _mission,
        rowsByCategory: _rows,
        ormScore: _ormScore,
      );
      _snackbar('PDF file saved successfully', Colors.green);
    } catch (e) {
      _snackbar('PDF export failed: $e', Colors.red);
    }
  }

  void _snackbar(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── validation banner ──────────────────────────────────────────
          if (_missingFields.isNotEmpty) _buildValidationBanner(),

          // ── Mission & Crew Information ─────────────────────────────────
          _buildMissionSection(),
          const SizedBox(height: 16),

          // ── one section per category ───────────────────────────────────
          for (final cat in CATEGORIES) ...[
            _buildCategorySection(cat),
            const SizedBox(height: 16),
          ],

          // ── ORM summary + export buttons ───────────────────────────────
          _buildResultsSection(),
        ],
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
        color: const Color(0xFF3B1010),
        border: Border.all(color: const Color(0xFF8B1010)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFFFB74D), size: 20),
              SizedBox(width: 8),
              Text(
                '⚠️  Form Incomplete!',
                style: TextStyle(
                  color: Color(0xFFFFB74D),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Please fill in the following required fields:',
            style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
          ),
          const SizedBox(height: 4),
          for (final f in _missingFields)
            Text(
              '• $f',
              style: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 13),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mission & Crew Information section  (mirrors the HTML layout)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMissionSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C3D2C), Color(0xFF0F2419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF4A6741)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mission & Crew Information',
            style: _sectionHeadingStyle(),
          ),
          const SizedBox(height: 14),

          // Pilot Name  |  Pilot Code
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
                      () => _mission = _mission.copyWith(pilotName: v)),
                ),
              ),
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
                      () => _mission = _mission.copyWith(pilotCode: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Second Pilot Name  |  Second Pilot Code
          Row(
            children: [
              Expanded(
                child: _missionTextField(
                  key: 'secondPilotName',
                  value: _mission.secondPilotName,
                  placeholder: 'Second Pilot Name',
                  capitalize: true,
                  onChanged: (v) => setState(
                      () => _mission = _mission.copyWith(secondPilotName: v)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _missionTextField(
                  key: 'secondPilotCode',
                  value: _mission.secondPilotCode,
                  placeholder: 'Second Pilot Code',
                  uppercase: true,
                  onChanged: (v) => setState(
                      () => _mission = _mission.copyWith(secondPilotCode: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mechanic Name (full width)
          _missionTextField(
            key: 'mechanicName',
            value: _mission.mechanicName,
            placeholder: 'Mechanic Name',
            capitalize: true,
            onChanged: (v) =>
                setState(() => _mission = _mission.copyWith(mechanicName: v)),
          ),
          const SizedBox(height: 10),

          // Mission Date  |  Mission Type
          Row(
            children: [
              Expanded(
                child: _missionDateField(),
              ),
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
                      () => _mission = _mission.copyWith(missionType: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mission-section TextEditingControllers (keyed so they survive rebuilds)
  // We store them lazily in a map so we never recreate a controller for the
  // same logical field.  Disposed in dispose().
  final Map<String, TextEditingController> _missionControllers = {};
  // Per-risk-row controllers keyed by row.id
  final Map<String, TextEditingController> _riskTitleControllers = {};
  final Map<String, TextEditingController> _riskDescControllers = {};
  final Map<String, TextEditingController> _riskDedControllers = {};

  TextEditingController _missionCtrl(String key, String initialValue) {
    if (!_missionControllers.containsKey(key)) {
      _missionControllers[key] = TextEditingController(text: initialValue);
    }
    return _missionControllers[key]!;
  }

  TextEditingController _riskTitleCtrl(String id, String initialValue) {
    if (!_riskTitleControllers.containsKey(id)) {
      _riskTitleControllers[id] = TextEditingController(text: initialValue);
    }
    return _riskTitleControllers[id]!;
  }

  TextEditingController _riskDescCtrl(String id, String initialValue) {
    if (!_riskDescControllers.containsKey(id)) {
      _riskDescControllers[id] = TextEditingController(text: initialValue);
    }
    return _riskDescControllers[id]!;
  }

  TextEditingController _riskDedCtrl(String id, String initialValue) {
    if (!_riskDedControllers.containsKey(id)) {
      _riskDedControllers[id] = TextEditingController(text: initialValue);
    }
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

  // Shared text field used in the mission section
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
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF777777)),
            filled: true,
            fillColor: const Color(0xFF162A1F),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isMissing
                    ? const Color(0xFF8B1010)
                    : const Color(0xFF4A6741),
              ),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isMissing
                    ? const Color(0xFF8B1010)
                    : const Color(0xFF4A6741),
              ),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFB8D4A8), width: 2),
              borderRadius: BorderRadius.zero,
            ),
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
              '*Required field',
              style: TextStyle(
                color: isMissing
                    ? const Color(0xFFFFCDD2)
                    : const Color(0xFF8A9A8A),
                fontSize: 11,
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
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            hintStyle: const TextStyle(color: Color(0xFF777777)),
            filled: true,
            fillColor: const Color(0xFF162A1F),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isMissing
                    ? const Color(0xFF8B1010)
                    : const Color(0xFF4A6741),
              ),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isMissing
                    ? const Color(0xFF8B1010)
                    : const Color(0xFF4A6741),
              ),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFB8D4A8), width: 2),
              borderRadius: BorderRadius.zero,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            prefixIcon: const Icon(Icons.calendar_today,
                color: Color(0xFF8A9A8A), size: 18),
          ),
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
          ],
          textInputAction: TextInputAction.next,
          onChanged: (v) {
            setState(() => _mission = _mission.copyWith(missionTime: v));
            _saveMission();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '📅 *Required field',
            style: TextStyle(
              color:
                  isMissing ? const Color(0xFFFFCDD2) : const Color(0xFF8A9A8A),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-category risk section
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategorySection(String cat) {
    final examples = _examplesFor(cat);
    final showDropdown = _showExampleDropdown[cat] ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C3D2C), Color(0xFF0F2419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF4A6741)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading
          Text(cat, style: _sectionHeadingStyle()),
          const SizedBox(height: 10),

          // ── existing risk rows ──
          for (final row in _rows[cat]!) ...[
            _buildRiskRow(cat, row),
            const SizedBox(height: 10),
          ],

          // ── "+ Add Risk"  &  "Use Example" buttons ──
          Row(
            children: [
              _actionButton(
                label: '+ Add Risk',
                color: const Color(0xFF4A6741),
                textColor: const Color(0xFFD4E8C8),
                onPressed: () => _addRisk(cat),
              ),
              const SizedBox(width: 10),
              if (examples.isNotEmpty)
                _actionButton(
                  label: 'Use Example',
                  color: const Color(0xFF2D5016),
                  textColor: const Color(0xFFD4E8C8),
                  onPressed: () =>
                      setState(() => _showExampleDropdown[cat] = !showDropdown),
                ),
            ],
          ),

          // ── example dropdown (visible when toggled) ──
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
        color: const Color(0xFF162A1F),
        border: Border.all(color: const Color(0xFF4A6741)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: null, // always null – selecting fires onChanged then resets
          hint: const Text('Select an example…',
              style: TextStyle(color: Color(0xFF777777))),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB8D4A8)),
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
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
  // Single risk row  (mirrors the HTML .input-row block)
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
        color: const Color(0xFF0F2419),
        border: Border.all(color: const Color(0xFF2A4A3A)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          TextField(
            controller: _riskTitleCtrl(row.id, row.title),
            style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
            decoration: _rowInputDecoration('Risk Title'),
            inputFormatters: [_CapitalizeFirstFormatter()],
            onChanged: (v) {
              row.title = v;
              _rebuildAndSave();
            },
          ),
          const SizedBox(height: 8),

          // ── Likelihood | Severity ──
          Row(
            children: [
              Expanded(child: _likelihoodDropdown(row)),
              const SizedBox(width: 10),
              Expanded(child: _severityDropdown(row)),
            ],
          ),
          const SizedBox(height: 8),

          // ── Description | Deduction ──
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
                  style:
                      const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
                  decoration: _rowInputDecoration('Deduction'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
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

          // ── Risk Value pill | Residual Risk pill | Delete button ──
          Row(
            children: [
              Expanded(
                child: _riskPill('Risk Value: ${row.riskValue.toInt()}',
                    riskPillBg, riskPillTxt),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _riskPill('Residual Risk: ${row.finalRiskValue.toInt()}',
                    finalPillBg, finalPillTxt),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() {
                  _removeRisk(cat, row.id);
                }),
                icon: const Icon(Icons.cancel,
                    color: Color(0xFFF44336), size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete',
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
        },
      );

  Widget _severityDropdown(_RiskRow row) => _buildScaleDropdown(
        value: row.severity,
        options: SEVERITY_OPTIONS,
        onChanged: (v) {
          row.severity = v;
          _rebuildAndSave();
        },
      );

  Widget _buildScaleDropdown({
    required int value,
    required List<Map<String, dynamic>> options,
    required void Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162A1F),
        border: Border.all(color: const Color(0xFF4A6741)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB8D4A8)),
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
          items: options.map((o) {
            final v = o['v'] as int;
            return DropdownMenuItem<int>(
              value: v,
              child: Text('$v - ${o['label']}'),
            );
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
        style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
        decoration: _rowInputDecoration('Description'),
        inputFormatters: [_CapitalizeFirstFormatter()],
        onChanged: (v) {
          row.description = v;
          _rebuildAndSave();
        },
      );

  Widget _descriptionDropdown(_RiskRow row) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF162A1F),
          border: Border.all(color: const Color(0xFF4A6741)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: row.description.isEmpty ? null : row.description,
            hint: const Text('Select a choice…',
                style: TextStyle(color: Color(0xFF777777))),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB8D4A8)),
            style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
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
  // Results section (ORM badges + export buttons)  – mirrors HTML #results
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildResultsSection() {
    final score = _ormScore;
    final catLabel = score != null ? riskCategoryFrom(score) : '-';
    final bg = score != null ? colorFromCategory(catLabel) : Colors.white;
    final txt = score != null ? textColorForCategory(catLabel) : Colors.black;
    final scoreText = score != null ? score.toInt().toString() : '-';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C3D2C), Color(0xFF0F2419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF4A6741)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ORM badges ──
          Row(
            children: [
              Expanded(
                child: _badge('ORM Risk: $scoreText', bg, txt),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _badge('Risk Category: $catLabel', bg, txt),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Export buttons ──
          Text('Export Options', style: _sectionHeadingStyle()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _exportButton(
                  label: '💾 Save to Excel',
                  bg: const Color(0xFF2D5016),
                  txtColor: const Color(0xFFD4E8C8),
                  onPressed: _exportToExcel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _exportButton(
                  label: '📝 Save as CSV',
                  bg: const Color(0xFF4A6741),
                  txtColor: const Color(0xFFD4E8C8),
                  onPressed: _exportToCSV,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _exportButton(
                  label: '📄 Save to PDF',
                  bg: const Color(0xFF8B5A00),
                  txtColor: const Color(0xFFFFE8C8),
                  onPressed: _exportToPDF,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Small builders / helpers
  // ═══════════════════════════════════════════════════════════════════════════
  void _rebuildAndSave() {
    setState(() {});
    _save();
  }

  TextStyle _sectionHeadingStyle() => const TextStyle(
        color: Color(0xFFB8D4A8),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  InputDecoration _rowInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF777777)),
        filled: true,
        fillColor: const Color(0xFF162A1F),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF4A6741)),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF4A6741)),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFFB8D4A8), width: 2),
          borderRadius: BorderRadius.zero,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

  Widget _riskPill(String text, Color bg, Color txtColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: bg.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: txtColor, fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );

  Widget _badge(String text, Color bg, Color txtColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: const Color(0xFFCCD6FF)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: txtColor, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      );

  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 0),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      );

  Widget _exportButton({
    required String label,
    required Color bg,
    required Color txtColor,
    required Future<void> Function() onPressed,
  }) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: txtColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(label, style: TextStyle(color: txtColor)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TextInputFormatters
// ─────────────────────────────────────────────────────────────────────────────

/// Capitalises only the very first character (mirrors JS capitalizeFirstLetter)
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

/// Forces all characters to uppercase (mirrors JS handleUppercaseCapitalization)
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/services/data_service.dart';

// ---------------------------------------------------------------------------
// Colour helpers (reused across matrix cells and category badges)
// ---------------------------------------------------------------------------
Color _matrixBg(int score) {
  if (score >= 21) return const Color(0xFF323232); // extreme  – near-black
  if (score >= 15) return const Color(0xFFF44336); // very high – red
  if (score >= 10) return const Color(0xFFFF9800); // high     – orange
  if (score >= 5) return const Color(0xFFFFC107); // moderate – yellow
  return const Color(0xFF4CAF50); // low      – green
}

Color _matrixTxt(int score) {
  // white text on dark backgrounds, black on yellow/green
  if (score >= 15) return Colors.white;
  return Colors.black;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class ReferenceTab extends StatefulWidget {
  const ReferenceTab({super.key});

  @override
  State<ReferenceTab> createState() => _ReferenceTabState();
}

class _ReferenceTabState extends State<ReferenceTab> {
  // ─── data ───────────────────────────────────────────────────────────────
  final DataService _dataService = DataService();
  Map<String, dynamic> _examples = {};
  bool _loading = true;

  // ─── modal state ────────────────────────────────────────────────────────
  // Add-hazard modal
  bool _showAddModal = false;
  String _addModalCategory = '';
  String _addModalName = '';
  List<String> _addModalChoices = [];

  // Remove-hazard modal
  bool _showRemoveModal = false;
  String _removeModalCategory = '';
  int _removeModalIndex = 0;

  // View / edit-example modal
  bool _showViewModal = false;
  String _viewModalCategory = '';
  int _viewModalIndex = 0;
  List<String> _viewModalChoices = [];

  // ─── controller for the "Add Hazard" name field (persists across rebuilds)
  final TextEditingController _addNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _addNameCtrl.dispose();
    super.dispose();
  }

  // ─── load ───────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    _examples = await _dataService.getCustomHazardExamples();
    setState(() {
      _loading = false;
    });
  }

  // ─── persist ────────────────────────────────────────────────────────────
  Future<void> _persist() async {
    await _dataService.saveCustomHazardExamples(_examples);
  }

  // ─── helpers: extract name / choices from a raw item ────────────────────
  static String _itemName(dynamic item) {
    if (item is Map) return (item['name'] as String?) ?? '';
    return item.toString();
  }

  static List<String> _itemChoices(dynamic item) {
    if (item is Map && item['choices'] is List) {
      return (item['choices'] as List).map((c) => c.toString()).toList();
    }
    return [];
  }

  List<dynamic> _listFor(String cat) {
    final raw = _examples[cat];
    return raw is List ? raw : [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    const catOrder = [
      'PLANNING',
      'INTERFACE (HUMAN-MACHINE)',
      'LEADERSHIP & SUPERVISION',
      'HUMAN FACTORS',
      'COMMUNICATIONS',
      'OPERATIONS / MISSION',
      'TASK PROFICIENCY AND CURRENCY',
      'EQUIPMENT',
      'REGULATIONS / RISK DECISIONS',
      'ENVIRONMENT',
    ];

    return Stack(
      children: [
        // ── scrollable body ──────────────────────────────────────────────
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLikelihoodSection(),
              const SizedBox(height: 16),
              _buildSeveritySection(),
              const SizedBox(height: 16),
              _buildRiskCalculationSection(),
              const SizedBox(height: 16),
              _buildExamplesSection(catOrder),
            ],
          ),
        ),

        // ── modals (rendered on top via Stack) ───────────────────────────
        if (_showAddModal) _buildAddModal(),
        if (_showRemoveModal) _buildRemoveModal(),
        if (_showViewModal) _buildViewModal(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Likelihood Scale
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLikelihoodSection() => _card(
        title: 'Likelihood Scale Definitions',
        child: _scaleTable([
          [
            1,
            'Very Improbable',
            'The event almost inconceivable that the event will occur. It has never occurred in the history of the aviation industry.'
          ],
          [
            2,
            'Improbable',
            'The event is very unlikely to occur. Not known to have occurred in the company but has already occurred at least once in the history of the aviation industry.'
          ],
          [
            3,
            'Remote',
            'The event is unlikely to occur, but possible. Has already occurred in the company at least once or has seldom occurred in the history of the aviation industry.'
          ],
          [
            4,
            'Probable',
            'The event is likely to occur sometimes. Has already occurred in the company. Has occurred infrequently in the history of the aviation industry.'
          ],
          [
            5,
            'Frequent',
            'The event is Likely to occur many times. Has already occurred in the company. Has occurred frequently in the history of the aviation industry.'
          ],
        ]),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Severity Scale
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSeveritySection() => _card(
        title: 'Severity Scale Definitions',
        child: _scaleTable([
          [
            1,
            'Negligible',
            'Minimal impact on mission, personnel, or equipment.'
          ],
          [
            2,
            'Minor',
            'Small impact that can be easily managed without significant consequences.'
          ],
          [
            3,
            'Major',
            'Significant impact requiring immediate attention and resources.'
          ],
          [
            4,
            'Critical',
            'Severe impact that could result in mission failure or serious injury.'
          ],
          [
            5,
            'Catastrophic',
            'Extreme impact resulting in loss of life, major equipment loss, or mission abort.'
          ],
        ]),
      );

  // Shared: Value / Category / Definition table
  Widget _scaleTable(List<List<dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        border: TableBorder.all(color: const Color(0xFF4A6741)),
        headingRowColor: WidgetStateProperty.all(const Color(0xFF4A6741)),
        columns: [
          DataColumn(label: _headerText('Value')),
          DataColumn(label: _headerText('Category')),
          DataColumn(label: _headerText('Definition')),
        ],
        rows: rows
            .map((r) => DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF0F2419)),
                  cells: [
                    DataCell(_boldCell(r[0].toString())),
                    DataCell(_boldCell(r[1].toString())),
                    DataCell(Text(r[2].toString(),
                        style: const TextStyle(
                            color: Color(0xFFE0E0E0), fontSize: 13))),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Risk Calculation & Score Matrix
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRiskCalculationSection() => _card(
        title: 'Risk Calculation & Score Matrix',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // formula
            const Text(
              'Formula: Risk Value = Likelihood × Severity − Deduction',
              style: TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Example: If Likelihood = 3 (Remote) and Severity = 4 (Critical), then Risk Value = 3 × 4 = 12 − 5 (Deduction), then Residual Risk Value = 7.',
              style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── 5×5 matrix ──
            const Text(
              'Risk Matrix (Likelihood × Severity)',
              style: TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 8),
            _buildRiskMatrix(),
            const SizedBox(height: 16),

            // ── score-range legend ──
            const Text(
              'Risk Categories by Score',
              style: TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 8),
            _buildScoreLegend(),
          ],
        ),
      );

  // 5×5 colour-coded matrix – rows high→low likelihood, cols low→high severity
  Widget _buildRiskMatrix() {
    // Column headers: severity labels (low→high)
    const sevHeaders = [
      'Negligible\n(1)',
      'Minor\n(2)',
      'Major\n(3)',
      'Critical\n(4)',
      'Catastrophic\n(5)'
    ];
    // Row definitions: [likelihood value, label]
    const likeRows = [
      [5, 'Frequent (5)'],
      [4, 'Probable (4)'],
      [3, 'Remote (3)'],
      [2, 'Improbable (2)'],
      [1, 'Very Improbable (1)'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row: empty corner + severity labels ──
          Row(
            children: [
              // corner cell (same width as the likelihood-label column)
              _matrixCorner(),
              ...sevHeaders.map((lbl) => _matrixHeaderCell(lbl)),
            ],
          ),
          // ── data rows ──
          ...likeRows.map((lr) {
            final like = lr[0] as int;
            final label = lr[1] as String;
            return Row(
              children: [
                _matrixRowHeader(label),
                ...[1, 2, 3, 4, 5].map((sev) {
                  final score = like * sev;
                  return _matrixDataCell(score);
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── matrix cell builders ──────────────────────────────────────────────
  static const double _mCellW = 90.0;
  static const double _mCellH = 44.0;
  static const double _mLabelW = 150.0;

  Widget _matrixCorner() => Container(
        width: _mLabelW,
        height: _mCellH,
        decoration: BoxDecoration(
          color: const Color(0xFF4A6741),
          border: Border.all(color: const Color(0xFF2A4A3A)),
        ),
        child: const Center(
          child: Text('Likelihood',
              style: TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      );

  Widget _matrixHeaderCell(String label) => Container(
        width: _mCellW,
        height: _mCellH,
        decoration: BoxDecoration(
          color: const Color(0xFF4A6741),
          border: Border.all(color: const Color(0xFF2A4A3A)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
              textAlign: TextAlign.center),
        ),
      );

  Widget _matrixRowHeader(String label) => Container(
        width: _mLabelW,
        height: _mCellH,
        decoration: BoxDecoration(
          color: const Color(0xFF4A6741),
          border: Border.all(color: const Color(0xFF2A4A3A)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      );

  Widget _matrixDataCell(int score) => Container(
        width: _mCellW,
        height: _mCellH,
        decoration: BoxDecoration(
          color: _matrixBg(score),
          border: Border.all(color: const Color(0xFF2A4A3A)),
        ),
        child: Center(
          child: Text(score.toString(),
              style: TextStyle(
                  color: _matrixTxt(score),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      );

  // Score-range legend table
  Widget _buildScoreLegend() {
    const rows = [
      ['1-4', 'Low Risk', 'Accept risk, monitor as needed'],
      ['5-9', 'Moderate Risk', 'Accept with controls, review periodically'],
      ['10-14', 'High Risk', 'Require mitigation, supervisor approval.'],
      ['15-20', 'Very High Risk', 'Require immediate action, command approval'],
      ['21-25', 'Extreme Risk', 'Mission abort/postpone, redesign required'],
    ];
    final badgeBg = {
      'Low Risk': const Color(0xFF2D5016),
      'Moderate Risk': const Color(0xFF8B5A00),
      'High Risk': const Color(0xFF8B4500),
      'Very High Risk': const Color(0xFF8B1010),
      'Extreme Risk': const Color(0xFF000000),
    };
    final badgeTxt = {
      'Low Risk': const Color(0xFFD4E8C8),
      'Moderate Risk': const Color(0xFFFFE8C8),
      'High Risk': const Color(0xFFFFE8C8),
      'Very High Risk': const Color(0xFFFFCCCC),
      'Extreme Risk': const Color(0xFFFF6B6B),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        border: TableBorder.all(color: const Color(0xFF4A6741)),
        headingRowColor: WidgetStateProperty.all(const Color(0xFF4A6741)),
        columns: [
          DataColumn(label: _headerText('Score Range')),
          DataColumn(label: _headerText('Risk Category')),
          DataColumn(label: _headerText('Action Required')),
        ],
        rows: rows
            .map((r) => DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF0F2419)),
                  cells: [
                    DataCell(_boldCell(r[0])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg[r[1]],
                          border: Border.all(color: const Color(0xFF4A6741)),
                        ),
                        child: Text(r[1],
                            style: TextStyle(
                                color: badgeTxt[r[1]],
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    DataCell(Text(r[2],
                        style: const TextStyle(
                            color: Color(0xFFE0E0E0), fontSize: 13))),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Examples section  (category rows with chips + Add / Remove buttons)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildExamplesSection(List<String> catOrder) => _card(
        title: 'Examples',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              catOrder.map((cat) => _buildExampleCategoryRow(cat)).toList(),
        ),
      );

  Widget _buildExampleCategoryRow(String cat) {
    final items = _listFor(cat);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2419),
        border: Border.all(color: const Color(0xFF2A4A3A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── left: category name + Add / Remove buttons ──
          Container(
            width: 180,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat,
                    style: const TextStyle(
                        color: Color(0xFFD4E8C8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _smallBtn('+ Add', const Color(0xFF6C7CFF),
                        () => _openAddModal(cat)),
                    const SizedBox(width: 6),
                    _smallBtn('Remove', const Color(0xFFFF4D4D),
                        () => _openRemoveModal(cat)),
                  ],
                ),
              ],
            ),
          ),
          // ── right: clickable example chips ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: items.isEmpty
                  ? const Text('No examples',
                      style: TextStyle(
                          color: Color(0xFF777777),
                          fontStyle: FontStyle.italic))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(items.length, (idx) {
                        final item = items[idx];
                        return GestureDetector(
                          onTap: () => _openViewModal(cat, idx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFeef2ff),
                              border:
                                  Border.all(color: const Color(0xFFC7D1FF)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _itemName(item),
                              style: const TextStyle(
                                  color: Color(0xFF1A1A2E), fontSize: 13),
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Modal openers
  // ─────────────────────────────────────────────────────────────────────────
  void _openAddModal(String cat) {
    _addNameCtrl.clear();
    setState(() {
      _showAddModal = true;
      _addModalCategory = cat;
      _addModalName = '';
      _addModalChoices = [];
    });
  }

  void _openRemoveModal(String cat) {
    setState(() {
      _showRemoveModal = true;
      _removeModalCategory = cat;
      _removeModalIndex = 0;
    });
  }

  void _openViewModal(String cat, int idx) {
    final item = _listFor(cat)[idx];
    setState(() {
      _showViewModal = true;
      _viewModalCategory = cat;
      _viewModalIndex = idx;
      _viewModalChoices = List.from(_itemChoices(item));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD modal
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAddModal() => _modal(
        title: 'Add New Hazard',
        onClose: () => setState(() => _showAddModal = false),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hazard name
            TextField(
              controller: _addNameCtrl,
              style: const TextStyle(color: Color(0xFFE0E0E0)),
              decoration: _modalInputDeco('Enter new hazard case'),
              onChanged: (v) => _addModalName = v,
            ),
            const SizedBox(height: 10),

            // existing choice inputs
            ...List.generate(
                _addModalChoices.length,
                (i) => Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                                text: _addModalChoices[i]),
                            style: const TextStyle(color: Color(0xFFE0E0E0)),
                            decoration: _modalInputDeco('Choice ${i + 1}'),
                            onChanged: (v) => _addModalChoices[i] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _smallBtn('Remove', const Color(0xFFFF4D4D),
                            () => setState(() => _addModalChoices.removeAt(i))),
                      ],
                    )),

            const SizedBox(height: 8),
            _smallBtn('+ Add Choice', const Color(0xFF6C7CFF),
                () => setState(() => _addModalChoices.add(''))),
          ],
        ),
        actions: [
          _modalBtn('Cancel', const Color(0xFFCCCCCC), Colors.black,
              () => setState(() => _showAddModal = false)),
          _modalBtn('Save', const Color(0xFF6C7CFF), Colors.white,
              () => _saveNewHazard()),
        ],
      );

  Future<void> _saveNewHazard() async {
    final name = _addModalName.trim();
    if (name.isEmpty) return;
    final choices = _addModalChoices
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    _examples[_addModalCategory] = _listFor(_addModalCategory);
    (_examples[_addModalCategory] as List)
        .add({'name': name, 'choices': choices});

    await _persist();
    setState(() {
      _showAddModal = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REMOVE modal
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRemoveModal() {
    final items = _listFor(_removeModalCategory);
    return _modal(
      title: 'Remove Hazard',
      onClose: () => setState(() => _showRemoveModal = false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Text('No items to remove.',
                style: TextStyle(
                    color: Color(0xFF777777), fontStyle: FontStyle.italic))
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF162A1F),
                border: Border.all(color: const Color(0xFF4A6741)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _removeModalIndex,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFFB8D4A8)),
                  style:
                      const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
                  items: List.generate(
                      items.length,
                      (i) => DropdownMenuItem<int>(
                            value: i,
                            child: Text(_itemName(items[i])),
                          )),
                  onChanged: (v) {
                    if (v != null) setState(() => _removeModalIndex = v);
                  },
                ),
              ),
            ),
        ],
      ),
      actions: [
        _modalBtn('Cancel', const Color(0xFFCCCCCC), Colors.black,
            () => setState(() => _showRemoveModal = false)),
        _modalBtn('Remove', const Color(0xFFFF4D4D), Colors.white,
            () => _removeHazard()),
      ],
    );
  }

  Future<void> _removeHazard() async {
    final list = _listFor(_removeModalCategory);
    if (_removeModalIndex < list.length) {
      list.removeAt(_removeModalIndex);
      _examples[_removeModalCategory] = list;
      await _persist();
    }
    setState(() {
      _showRemoveModal = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VIEW / EDIT modal  (shows example name + editable choices list)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildViewModal() {
    final items = _listFor(_viewModalCategory);
    final name = _viewModalIndex < items.length
        ? _itemName(items[_viewModalIndex])
        : '…';

    return _modal(
      title: name,
      onClose: () => setState(() => _showViewModal = false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choices',
              style: TextStyle(
                  color: Color(0xFFD4E8C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 6),
          if (_viewModalChoices.isEmpty)
            const Text('No choices',
                style: TextStyle(
                    color: Color(0xFF777777), fontStyle: FontStyle.italic))
          else
            ...List.generate(
                _viewModalChoices.length,
                (i) => Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                                text: _viewModalChoices[i]),
                            style: const TextStyle(color: Color(0xFFE0E0E0)),
                            decoration: _modalInputDeco('Choice'),
                            onChanged: (v) => _viewModalChoices[i] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _smallBtn(
                            'Remove',
                            const Color(0xFFFF4D4D),
                            () =>
                                setState(() => _viewModalChoices.removeAt(i))),
                      ],
                    )),
          const SizedBox(height: 8),
          _smallBtn('+ Add Choice', const Color(0xFF6C7CFF),
              () => setState(() => _viewModalChoices.add(''))),
        ],
      ),
      actions: [
        _modalBtn('Close', const Color(0xFFFF4D4D), Colors.white,
            () => setState(() => _showViewModal = false)),
        _modalBtn('Save', const Color(0xFF6C7CFF), Colors.white,
            () => _saveExampleChoices()),
      ],
    );
  }

  Future<void> _saveExampleChoices() async {
    final list = _listFor(_viewModalCategory);
    if (_viewModalIndex < list.length) {
      final item = list[_viewModalIndex];
      final cleaned = _viewModalChoices
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (item is Map) {
        item['choices'] = cleaned;
      } else {
        // upgrade legacy string item to object
        list[_viewModalIndex] = {'name': _itemName(item), 'choices': cleaned};
      }
      _examples[_viewModalCategory] = list;
      await _persist();
    }
    setState(() {
      _showViewModal = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared UI builders
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dark-green gradient card with a heading
  static Widget _card({required String title, required Widget child}) =>
      Container(
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
            Text(title,
                style: const TextStyle(
                    color: Color(0xFFB8D4A8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  /// White bold table-header text
  static const Widget Function(String) _headerText = _HeaderText.new;

  /// Bold green cell text
  static Widget _boldCell(String t) => Text(t,
      style: const TextStyle(
          color: Color(0xFFD4E8C8), fontWeight: FontWeight.bold, fontSize: 13));

  /// Small coloured button used in the examples rows and inside modals
  static Widget _smallBtn(String label, Color bg, VoidCallback onPressed) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: const Size(0, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      );

  /// Modal shell – dark overlay + centred content card
  Widget _modal({
    required String title,
    required VoidCallback onClose,
    required Widget body,
    required List<Widget> actions,
  }) =>
      Positioned.fill(
        child: GestureDetector(
          onTap: onClose, // tap outside → close
          child: Container(
            color: const Color(0xDD000000),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // swallow taps inside the card
                child: Container(
                  width: 520,
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border:
                        Border.all(color: const Color(0xFF4A6741), width: 3),
                    boxShadow: [
                      const BoxShadow(
                          color: Color(0xCC000000),
                          blurRadius: 32,
                          offset: Offset(0, 8)),
                      const BoxShadow(color: Color(0x4D4A6741), blurRadius: 60),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Color(0xFFB8D4A8),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      body,
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  /// Standard dark input decoration used inside modals
  static InputDecoration _modalInputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF777777)),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF444444)),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF444444)),
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

  /// Button used in modal footer rows
  static Widget _modalBtn(
          String label, Color bg, Color txtColor, VoidCallback onPressed) =>
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: txtColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(label, style: TextStyle(color: txtColor)),
        ),
      );
}

// ---------------------------------------------------------------------------
// Tiny helper widget so we can use _headerText as a const-compatible factory
// ---------------------------------------------------------------------------
class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: Color(0xFFD4E8C8), fontWeight: FontWeight.bold),
      );
}

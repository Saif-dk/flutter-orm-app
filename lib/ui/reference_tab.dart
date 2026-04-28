import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/services/data_service.dart';

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
// Colour helpers for matrix cells
// ---------------------------------------------------------------------------
Color _matrixBg(int score) {
  if (score >= 21) return const Color(0xFF323232);
  if (score >= 15) return const Color(0xFFF44336);
  if (score >= 10) return const Color(0xFFFF9800);
  if (score >= 5) return const Color(0xFFFFC107);
  return const Color(0xFF4CAF50);
}

Color _matrixTxt(int score) => score >= 15 ? Colors.white : Colors.black;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class ReferenceTab extends StatefulWidget {
  const ReferenceTab({super.key});

  @override
  State<ReferenceTab> createState() => _ReferenceTabState();
}

class _ReferenceTabState extends State<ReferenceTab> {
  final DataService _dataService = DataService();
  Map<String, dynamic> _examples = {};
  bool _loading = true;

  bool _showAddModal = false;
  String _addModalCategory = '';
  String _addModalName = '';
  List<String> _addModalChoices = [];

  bool _showRemoveModal = false;
  String _removeModalCategory = '';
  int _removeModalIndex = 0;

  bool _showViewModal = false;
  String _viewModalCategory = '';
  int _viewModalIndex = 0;
  List<String> _viewModalChoices = [];

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

  Future<void> _loadData() async {
    _examples = await _dataService.getCustomHazardExamples();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _persist() async =>
      await _dataService.saveCustomHazardExamples(_examples);

  static String _itemName(dynamic item) {
    if (item is Map) return (item['name'] as String?) ?? '';
    return item.toString();
  }

  static List<String> _itemChoices(dynamic item) {
    if (item is Map && item['choices'] is List)
      return (item['choices'] as List).map((c) => c.toString()).toList();
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
      return Container(
        color: _cBackground,
        child:
            const Center(child: CircularProgressIndicator(color: _cLetterLit)),
      );
    }

    const catOrder = [
      'HUMAN FACTORS',
      'ENVIRONMENT',
      'LEADERSHIP & SUPERVISION',
      'INTERFACE (HUMAN-MACHINE)',
      'COMMUNICATIONS',
      'OPERATIONS / MISSION',
      'PLANNING',
      'TASK PROFICIENCY AND CURRENCY',
      'EQUIPMENT',
      'REGULATIONS / RISK DECISIONS',
    ];

    return Container(
      color: _cBackground,
      child: Stack(
        children: [
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
          if (_showAddModal) _buildAddModal(),
          if (_showRemoveModal) _buildRemoveModal(),
          if (_showViewModal) _buildViewModal(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Likelihood Scale
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLikelihoodSection() => _card(
        title: 'LIKELIHOOD SCALE',
        child: _scaleTable([
          [
            1,
            'Very Improbable',
            'Almost inconceivable – never occurred in aviation industry history.'
          ],
          [
            2,
            'Improbable',
            'Very unlikely – not known in company, but has occurred in industry.'
          ],
          [
            3,
            'Remote',
            'Unlikely but possible – has occurred in company at least once.'
          ],
          [
            4,
            'Probable',
            'Likely sometimes – has occurred in company, infrequent in industry.'
          ],
          [
            5,
            'Frequent',
            'Likely many times – occurred frequently in company and industry.'
          ],
        ]),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Severity Scale
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSeveritySection() => _card(
        title: 'SEVERITY SCALE',
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

  Widget _scaleTable(List<List<dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        border: TableBorder.all(color: _cBorder),
        headingRowColor: WidgetStateProperty.all(_cSurface),
        columns: [
          DataColumn(label: _headerText('Value')),
          DataColumn(label: _headerText('Category')),
          DataColumn(label: _headerText('Definition')),
        ],
        rows: rows
            .map((r) => DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF060E18)),
                  cells: [
                    DataCell(_numCell(r[0].toString())),
                    DataCell(_boldCell(r[1].toString())),
                    DataCell(Text(r[2].toString(),
                      style: const TextStyle(
                        color: _cTextPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
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
        title: 'RISK CALCULATION & SCORE MATRIX',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _cAccent.withOpacity(0.10),
                border: Border(left: BorderSide(color: _cLetterLit, width: 3)),
              ),
              child: const Text(
                'Formula: Risk Value = Likelihood × Severity − Deduction',
                style: TextStyle(
                    color: _cLetterGlow,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: Likelihood = 3 (Remote) × Severity = 4 (Critical) = 12 − 5 (Deduction) → Residual Risk = 7',
              style: TextStyle(color: _cTextSub, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _hudLabel('RISK MATRIX (LIKELIHOOD × SEVERITY)'),
            const SizedBox(height: 8),
            _buildRiskMatrix(),
            const SizedBox(height: 16),
            _hudLabel('RISK CATEGORIES BY SCORE'),
            const SizedBox(height: 8),
            _buildScoreLegend(),
          ],
        ),
      );

  // 5×5 colour-coded matrix
  Widget _buildRiskMatrix() {
    const sevHeaders = [
      'Negligible\n(1)',
      'Minor\n(2)',
      'Major\n(3)',
      'Critical\n(4)',
      'Catastrophic\n(5)'
    ];
    const likeRows = [
      [5, 'Frequent (5)'],
      [4, 'Probable (4)'],
      [3, 'Remote (3)'],
      [2, 'Improbable (2)'],
      [1, 'Very Improbable (1)']
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _matrixCorner(),
              ...sevHeaders.map((lbl) => _matrixHeaderCell(lbl)),
            ],
          ),
          ...likeRows.map((lr) {
            final like = lr[0] as int;
            final label = lr[1] as String;
            return Row(
              children: [
                _matrixRowHeader(label),
                ...[1, 2, 3, 4, 5].map((sev) => _matrixDataCell(like * sev)),
              ],
            );
          }),
        ],
      ),
    );
  }

  static const double _mCellW = 90.0;
  static const double _mCellH = 44.0;
  static const double _mLabelW = 160.0;

  Widget _matrixCorner() => Container(
        width: _mLabelW,
        height: _mCellH,
        decoration: BoxDecoration(
            color: _cSurface, border: Border.all(color: _cBorder)),
        child: const Center(
            child: Text('Likelihood ↕',
              style: TextStyle(
                color: _cLetterLit,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5))),
      );

  Widget _matrixHeaderCell(String label) => Container(
        width: _mCellW,
        height: _mCellH,
        decoration: BoxDecoration(
            color: _cSurface, border: Border.all(color: _cBorder)),
        child: Center(
        child: Text(label,
          style: const TextStyle(
            color: _cGreenFg,
            fontWeight: FontWeight.w700,
            fontSize: 13),
          textAlign: TextAlign.center)),
      );

  Widget _matrixRowHeader(String label) => Container(
        width: _mLabelW,
        height: _mCellH,
        decoration: BoxDecoration(
            color: _cSurface, border: Border.all(color: _cBorder)),
        child: Center(
        child: Text(label,
          style: const TextStyle(
            color: _cGreenFg,
            fontWeight: FontWeight.w700,
            fontSize: 12))),
      );

  Widget _matrixDataCell(int score) => Container(
        width: _mCellW,
        height: _mCellH,
        decoration: BoxDecoration(
            color: _matrixBg(score), border: Border.all(color: _cBorder)),
        child: Center(
        child: Text(score.toString(),
          style: TextStyle(
            color: _matrixTxt(score),
            fontWeight: FontWeight.w900,
            fontSize: 16))),
      );

  Widget _buildScoreLegend() {
    const rows = [
      ['1–4', 'Low Risk', 'Accept risk, monitor as needed'],
      ['5–9', 'Moderate Risk', 'Accept with controls, review periodically'],
      ['10–14', 'High Risk', 'Require mitigation, supervisor approval'],
      ['15–20', 'Very High Risk', 'Require immediate action, command approval'],
      ['21–25', 'Extreme Risk', 'Mission abort/postpone, redesign required'],
    ];
    final badgeBg = {
      'Low Risk': const Color(0xFF1A3A08),
      'Moderate Risk': const Color(0xFF3A2800),
      'High Risk': const Color(0xFF3A1800),
      'Very High Risk': const Color(0xFF3A0808),
      'Extreme Risk': const Color(0xFF1A1A1A),
    };
    final badgeTxt = {
      'Low Risk': const Color(0xFF90EE60),
      'Moderate Risk': const Color(0xFFFFE8C8),
      'High Risk': const Color(0xFFFFCC80),
      'Very High Risk': const Color(0xFFFF8080),
      'Extreme Risk': const Color(0xFFFF4040),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        border: TableBorder.all(color: _cBorder),
        headingRowColor: WidgetStateProperty.all(_cSurface),
        columns: [
          DataColumn(label: _headerText('Score')),
          DataColumn(label: _headerText('Category')),
          DataColumn(label: _headerText('Action Required')),
        ],
        rows: rows
            .map((r) => DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF060E18)),
                  cells: [
                    DataCell(_numCell(r[0])),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg[r[1]],
                        border: Border.all(
                            color: (badgeTxt[r[1]] ?? Colors.white)
                                .withOpacity(0.3)),
                      ),
                      child: Text(r[1],
                        style: TextStyle(
                          color: badgeTxt[r[1]],
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5)),
                    )),
                    DataCell(Text(r[2],
                      style: const TextStyle(
                        color: _cTextPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Examples section
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildExamplesSection(List<String> catOrder) => _card(
        title: 'HAZARD EXAMPLES',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              catOrder.map((cat) => _buildExampleCategoryRow(cat)).toList(),
        ),
      );

  Widget _buildExampleCategoryRow(String cat) {
    final items = _listFor(cat);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF060E18),
        border: Border.all(color: _cBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left column
          Container(
            width: 180,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: _cBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat,
                  style: const TextStyle(
                    color: _cLetterLit,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _smallBtn('+ Add', const Color(0xFF1A2060), _cTextSub,
                        () => _openAddModal(cat)),
                    const SizedBox(width: 6),
                    _smallBtn('Remove', const Color(0xFF3A0808),
                        const Color(0xFFFF6060), () => _openRemoveModal(cat)),
                  ],
                ),
              ],
            ),
          ),
          // right: chips
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: items.isEmpty
                    ? const Text('No hazards',
                      style: TextStyle(
                        color: Color(0xFF3A5A4A),
                        fontStyle: FontStyle.italic,
                        fontSize: 13, fontWeight: FontWeight.bold))
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
                              color: _cAccent.withOpacity(0.08),
                              border: Border.all(
                                  color: _cBorderBright.withOpacity(0.5)),
                            ),
                            child: Text(_itemName(item),
                              style: const TextStyle(
                                color: _cGreenFg,
                                fontSize: 13,
                                letterSpacing: 0.3, fontWeight: FontWeight.bold)),
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
        title: 'ADD NEW HAZARD',
        onClose: () => setState(() => _showAddModal = false),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _addNameCtrl,
              style: const TextStyle(color: _cTextPrimary),
              decoration: _modalInputDeco('Enter new hazard case'),
              onChanged: (v) => _addModalName = v,
            ),
            const SizedBox(height: 10),
            ...List.generate(
                _addModalChoices.length,
                (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                  text: _addModalChoices[i]),
                              style: const TextStyle(color: _cTextPrimary),
                              decoration: _modalInputDeco('Choice ${i + 1}'),
                              onChanged: (v) => _addModalChoices[i] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _smallBtn(
                              'Remove',
                              const Color(0xFF3A0808),
                              const Color(0xFFFF6060),
                              () =>
                                  setState(() => _addModalChoices.removeAt(i))),
                        ],
                      ),
                    )),
            const SizedBox(height: 8),
            _smallBtn('+ Add Choice', const Color(0xFF1A2060), _cTextSub,
                () => setState(() => _addModalChoices.add(''))),
          ],
        ),
        actions: [
          _modalBtn('Cancel', _cSurface, _cTextSub,
              () => setState(() => _showAddModal = false)),
          _modalBtn('Save', _cAccent.withOpacity(0.20), _cLetterLit,
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
      title: 'REMOVE HAZARD',
      onClose: () => setState(() => _showRemoveModal = false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Text('No items to remove.',
                style: TextStyle(
                    color: Color(0xFF4A6060), fontStyle: FontStyle.italic))
          else
            Container(
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 9, 26, 15),
                  border: Border.all(color: _cBorder)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _removeModalIndex,
                  dropdownColor: const Color(0xFF0A1A10),
                  icon: const Icon(Icons.arrow_drop_down, color: _cLetterLit),
                  style: const TextStyle(color: _cTextPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  items: List.generate(
                      items.length,
                      (i) => DropdownMenuItem<int>(
                          value: i, child: Text(_itemName(items[i])))),
                  onChanged: (v) {
                    if (v != null) setState(() => _removeModalIndex = v);
                  },
                ),
              ),
            ),
        ],
      ),
      actions: [
        _modalBtn('Cancel', _cSurface, _cTextSub,
            () => setState(() => _showRemoveModal = false)),
        _modalBtn('Remove', const Color(0xFF3A0808), const Color(0xFFFF6060),
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
  // VIEW / EDIT modal
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildViewModal() {
    final items = _listFor(_viewModalCategory);
    final name = _viewModalIndex < items.length
        ? _itemName(items[_viewModalIndex])
        : '…';

    return _modal(
      title: name.toUpperCase(),
      onClose: () => setState(() => _showViewModal = false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHOICES',
              style: TextStyle(
                  color: _cLetterLit,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          if (_viewModalChoices.isEmpty)
            const Text('No choices',
                style: TextStyle(
                    color: Color(0xFF4A6060), fontStyle: FontStyle.italic))
          else
            ...List.generate(
                _viewModalChoices.length,
                (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                  text: _viewModalChoices[i]),
                              style: const TextStyle(color: _cTextPrimary),
                              decoration: _modalInputDeco('Choice'),
                              onChanged: (v) => _viewModalChoices[i] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _smallBtn(
                              'Remove',
                              const Color(0xFF3A0808),
                              const Color(0xFFFF6060),
                              () => setState(
                                  () => _viewModalChoices.removeAt(i))),
                        ],
                      ),
                    )),
          const SizedBox(height: 8),
          _smallBtn('+ Add Choice', const Color(0xFF1A2060), _cTextSub,
              () => setState(() => _viewModalChoices.add(''))),
        ],
      ),
      actions: [
        _modalBtn('Close', _cSurface, _cTextSub,
            () => setState(() => _showViewModal = false)),
        _modalBtn('Save', _cAccent.withOpacity(0.20), _cLetterLit,
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

  Widget _card({required String title, required Widget child}) => Container(
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
                    Text(title,
                      style: const TextStyle(
                        color: _cLetterLit,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 2.5)),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(14), child: child),
          ],
        ),
      );

  Widget _hudLabel(String text) => Row(
        children: [
            const Text('▸ ', style: TextStyle(color: _cAccent, fontSize: 6, fontWeight: FontWeight.bold)),
            Text(text,
              style: const TextStyle(
                color: _cTextSub,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w700)),
        ],
      );

    static Widget _headerText(String t) => Text(t,
      style: const TextStyle(
        color: _cLetterLit,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 1));

    static Widget _boldCell(String t) => Text(t,
      style: const TextStyle(
        color: _cGreenFg, fontWeight: FontWeight.w700, fontSize: 14));

    static Widget _numCell(String t) => Text(t,
      style: const TextStyle(
        color: _cLetterLit,
        fontWeight: FontWeight.w900,
        fontSize: 15,
        letterSpacing: 1));

  static Widget _smallBtn(
          String label, Color bg, Color txtColor, VoidCallback onPressed) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: bg, border: Border.all(color: txtColor.withOpacity(0.4))),
            child: Text(label,
              style: TextStyle(
                  color: txtColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
      );

  Widget _modal(
          {required String title,
          required VoidCallback onClose,
          required Widget body,
          required List<Widget> actions}) =>
      Positioned.fill(
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            color: const Color(0xDD000000),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 520,
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050D12),
                    border: Border.all(color: _cBorderBright, width: 1.5),
                    boxShadow: [
                      const BoxShadow(
                          color: Color(0xCC000000),
                          blurRadius: 32,
                          offset: Offset(0, 8)),
                      BoxShadow(
                          color: _cAccent.withOpacity(0.08), blurRadius: 60),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 16, color: _cLetterLit),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(title,
                              style: const TextStyle(
                                color: _cLetterLit,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2)),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close,
                                color: Color(0xFF4A6060), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(height: 1, color: _cBorder),
                      const SizedBox(height: 14),
                      body,
                      const SizedBox(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  static InputDecoration _modalInputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4A6060)),
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

  static Widget _modalBtn(
          String label, Color bg, Color txtColor, VoidCallback onPressed) =>
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: txtColor.withOpacity(0.4))),
            child: Text(label,
              style: TextStyle(
                color: txtColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1)),
          ),
        ),
      );
}

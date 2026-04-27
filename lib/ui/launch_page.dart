import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/ui/home_page.dart';
import 'package:orm_risk_assessment/ui/assessment_tab.dart';
import 'package:orm_risk_assessment/utils/launch_audio.dart';

// ─── colour tokens ────────────────────────────────────────────────────────────
const _cBackground = Color(0xFF090C1A);
const _cSurface = Color.fromARGB(255, 14, 40, 28);
const _cBorder = Color.fromARGB(255, 30, 107, 57);
const _cBorderBright = Color.fromARGB(255, 45, 201, 89);
const _cAccent = Color.fromARGB(255, 61, 232, 121);
const _cAccentGlow = Color.fromARGB(255, 79, 255, 164);
const _cLetterDim = Color.fromARGB(255, 26, 80, 40);
const _cLetterLit = Color.fromARGB(255, 79, 255, 146);
const _cLetterGlow = Color.fromARGB(255, 170, 255, 194);
const _cGreen = Color(0xFF4A8C40);
const _cGreenFg = Color(0xFFBBE0B0);
const _cGreenBorder = Color(0xFF5A9E50);
const _cTextPrimary = Color(0xFFDDE3FF);
const _cTextSub = Color(0xFF6677CC);

// ─── HELICOPTER acronym data ─────────────────────────────────────────────────
const List<String> _letters = [
  'H',
  'E',
  'L',
  'I',
  'C',
  'O',
  'P',
  'T',
  'E',
  'R'
];
const List<String> _acronyms = [
  'Human Factor',
  'Environment',
  'Leadership & Supervision',
  'Interface',
  'Communication',
  'Operation/Mission',
  'Planning',
  'Task Proficiency/Currency',
  'Equipment',
  'Risk Decision/Regulation',
];
const List<String> _descriptions = [
  'Assess crew fitness, fatigue, health, and experience level that may affect mission performance.',
  'Evaluate weather, terrain, lighting conditions, and environmental hazards impacting the operation.',
  'Review quality of leadership, crew coordination, supervision, and chain-of-command effectiveness.',
  'Identify human-machine interface issues, cockpit ergonomics, and system usability concerns.',
  'Examine clarity of crew briefs, ATC coordination, and inter-crew communication standards.',
  'Analyse mission complexity, operational tempo, and alignment with unit capabilities.',
  'Review mission planning thoroughness, contingency preparation, and route/fuel analysis.',
  'Assess individual crew task proficiency, currency, and recency of relevant training.',
  'Inspect aircraft airworthiness, equipment serviceability, and availability of required gear.',
  'Evaluate risk acceptance authority, regulatory compliance, and go/no-go decision criteria.',
];

// ─── LaunchPage ───────────────────────────────────────────────────────────────
class LaunchPage extends StatefulWidget {
  const LaunchPage({Key? key}) : super(key: key);
  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with TickerProviderStateMixin {
  // letter-light animation
  late AnimationController _letterController;
  int _litCount = 0;
  Timer? _letterTimer;

  // radar pulse
  late AnimationController _radarController;

  // scanline scroll
  late AnimationController _scanController;

  // grid flicker
  late AnimationController _gridController;

  // launch fly-out
  late AnimationController _launchController;
  late Animation<double> _launchProgress;
  bool _launched = false;

  // selected letter (null = nothing selected)
  int? _selected;

  // blink timer for cursor
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  // helicopter image size and button metrics
  final double _helicopterHeight = 250.0;
  final double _buttonHeight = 40.0;
  final double _buttonBottomPadding = 70.0;
  // audio bridge (web or no-op)

  @override
  void initState() {
    super.initState();

    // Radar
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Scanline
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Grid flicker
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..repeat(reverse: true);

    // Letter-by-letter lighting
    _letterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _startLetterSequence();

    // Cursor blink
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });

    // Launch
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _launchProgress = CurvedAnimation(
      parent: _launchController,
      curve: Curves.easeInCubic,
    );
    _launchController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });

    // prepare audio player
    // no-op for non-web; web implementation will play via `dart:html`
  }

  void _startLetterSequence() {
    // Reset
    setState(() => _litCount = 0);
    _letterTimer = Timer.periodic(const Duration(milliseconds: 140), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _litCount++;
      });
      if (_litCount >= _letters.length) {
        t.cancel();
        // After a pause, restart the sequence for a looping effect
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted && !_launched) {
            _startLetterSequence();
          }
        });
      }
    });
  }

  void _launch() {
    if (_launched) return;
    setState(() => _launched = true);
    _letterTimer?.cancel();
    _cursorTimer?.cancel();
    // play helicopter sound and start launch animation
    try {
      playLaunchAudio();
    } catch (_) {}
    _launchController.forward();
  }

  @override
  void dispose() {
    _letterController.dispose();
    _radarController.dispose();
    _scanController.dispose();
    _gridController.dispose();
    _launchController.dispose();
    disposeLaunchAudio();
    _letterTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _cBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _launchProgress,
          _radarController,
          _scanController,
        ]),
        builder: (ctx, _) {
          final p = _launchProgress.value;
          // At rest (p=0): helicopter bottom aligns with button top edge
          final restingBottom = _buttonBottomPadding + _buttonHeight;
          final heliBottom =
              restingBottom + (size.height + _helicopterHeight) * p;
          final pageOpacity = (1.0 - p * 1.8).clamp(0.0, 1.0);

          return Opacity(
            opacity: pageOpacity,
            child: Stack(
              children: [
                // ── Grid background ──────────────────────────────────────────
                Positioned.fill(
                    child: _GridPainter(controller: _gridController)),

                // ── Scanline overlay ─────────────────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter:
                          _ScanlinePainter(_scanController.value, size.height),
                    ),
                  ),
                ),

                // ── Main content ─────────────────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        _buildTopBar(),
                        const SizedBox(height: 20),
                        _buildRadarRow(size),
                        const SizedBox(height: 18),
                        _buildHelicopterTitle(),
                        const SizedBox(height: 6),
                        _buildSubtitle(),
                        const SizedBox(height: 18),
                        _buildLetterGrid(),
                        const SizedBox(height: 14),
                        _buildInfoCard(),
                        const Spacer(),
                        _buildStatusBar(),
                        const SizedBox(height: 10),
                        _buildLaunchButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Helicopter GIF (non-interactive so it doesn't block taps) ───
                Positioned(
                  bottom: heliBottom,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Image.asset(
                        'assets/GIF/helicopter.gif',
                        height: _helicopterHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 14, 40, 19),
        border: Border.all(color: const Color.fromARGB(255, 30, 107, 63)),
        boxShadow: [
          BoxShadow(
              color: const Color.fromARGB(255, 61, 232, 112).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // ORM badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cAccent.withOpacity(0.15),
              border:
                  Border.all(color: const Color.fromARGB(255, 45, 201, 115)),
            ),
            child: const Text(
              'ORM',
              style: TextStyle(
                color: Color.fromARGB(255, 79, 255, 138),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('OPERATIONAL RISK',
                    style: TextStyle(
                        color: _cTextPrimary,
                        fontSize: 16,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700)),
                Text('MANAGEMENT SYSTEM',
                    style: TextStyle(
                        color: Color.fromARGB(255, 102, 204, 145),
                        fontSize: 15,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
          // Live indicator
          _PulsingDot(),
          const SizedBox(width: 6),
          const Text('SYS ONLINE',
              style: TextStyle(
                  color: Color(0xFF60DD80), fontSize: 15, letterSpacing: 1.4)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 30, 107, 61)),
              color: const Color.fromARGB(255, 9, 26, 15),
            ),
            child: const Text('31 UA',
                style: TextStyle(
                    color: Color.fromARGB(255, 102, 204, 146),
                    fontSize: 16,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  // ─── RADAR ROW ───────────────────────────────────────────────────────────────
  Widget _buildRadarRow(Size size) {
    return Row(
      children: [
        // Mini radar
        SizedBox(
          width: 72,
          height: 72,
          child: AnimatedBuilder(
            animation: _radarController,
            builder: (_, __) => CustomPaint(
              painter: _RadarPainter(_radarController.value),
            ),
          ),
        ),
        const SizedBox(width: 19),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HUDRow(label: 'MISSION', value: 'ORM ASSESSMENT'),
              const SizedBox(height: 4),
              _HUDRow(label: 'STATUS', value: 'STANDBY'),
              const SizedBox(height: 4),
              _HUDRow(label: 'UNIT', value: '31st AVIATION'),
            ],
          ),
        ),
        // Vertical divider with ticks
        Container(
          width: 29,
          height: 72,
          child: CustomPaint(painter: _TickPainter()),
        ),
      ],
    );
  }

  // ─── HELICOPTER TITLE ────────────────────────────────────────────────────────
  Widget _buildHelicopterTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_letters.length, (i) {
        final lit = i < _litCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 37,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: lit
                  ? const Color.fromARGB(255, 79, 255, 123)
                  : const Color.fromARGB(255, 26, 80, 41),
              shadows: lit
                  ? [
                      Shadow(
                          color: const Color.fromARGB(255, 170, 255, 213),
                          blurRadius: 12),
                      Shadow(
                          color: const Color.fromARGB(255, 61, 232, 109),
                          blurRadius: 28),
                    ]
                  : [],
            ),
            child: Text(_letters[i]),
          ),
        );
      }),
    );
  }

  // ─── SUBTITLE ────────────────────────────────────────────────────────────────
  Widget _buildSubtitle() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'RISK ASSESSMENT MODEL',
            style: TextStyle(
                color: Color.fromARGB(255, 102, 204, 150),
                fontSize: 16,
                letterSpacing: 3),
          ),
          const SizedBox(width: 4),
          AnimatedOpacity(
            opacity: _cursorVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 80),
            child: const Text('█',
                style: TextStyle(
                    color: Color.fromARGB(255, 61, 232, 118), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ─── LETTER GRID ─────────────────────────────────────────────────────────────
  Widget _buildLetterGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_letters.length, (i) {
        final isSelected = _selected == i;
        final isLit = i < _litCount;
        return GestureDetector(
          onTap: () => setState(() => _selected = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromARGB(255, 61, 232, 135).withOpacity(0.20)
                  : const Color.fromARGB(255, 14, 40, 22).withOpacity(0.8),
              border: Border.all(
                color: isSelected
                    ? const Color.fromARGB(255, 79, 255, 100)
                    : (isLit
                        ? const Color.fromARGB(255, 45, 201, 110)
                            .withOpacity(0.6)
                        : _cBorder),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: const Color.fromARGB(255, 61, 232, 109)
                              .withOpacity(0.35),
                          blurRadius: 14)
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _letters[i],
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isSelected
                        ? const Color.fromARGB(255, 170, 255, 197)
                        : (isLit
                            ? const Color.fromARGB(255, 79, 255, 120)
                            : const Color.fromARGB(255, 102, 204, 102)),
                    shadows: isSelected
                        ? [
                            Shadow(
                                color: const Color.fromARGB(255, 79, 255, 141),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? const Color.fromARGB(255, 61, 232, 127)
                        : const Color.fromARGB(255, 26, 80, 54),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── INFO CARD ───────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _selected == null
          ? Container(
              key: const ValueKey('empty'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 14, 40, 19),
                border: Border(
                  left: BorderSide(
                      color: const Color.fromARGB(255, 30, 107, 80), width: 3),
                  top:
                      BorderSide(color: const Color.fromARGB(255, 30, 107, 52)),
                  right:
                      BorderSide(color: const Color.fromARGB(255, 30, 107, 75)),
                  bottom:
                      BorderSide(color: const Color.fromARGB(255, 30, 107, 67)),
                ),
              ),
              child: const Center(
                child: Text(
                  'SELECT A LETTER TO VIEW DETAILS',
                  style: TextStyle(
                    color: Color.fromARGB(255, 45, 120, 70),
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            )
          : Container(
              key: ValueKey(_selected),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 14, 40, 19),
                border: Border(
                  left: BorderSide(
                      color: const Color.fromARGB(255, 79, 255, 161), width: 3),
                  top:
                      BorderSide(color: const Color.fromARGB(255, 30, 107, 52)),
                  right:
                      BorderSide(color: const Color.fromARGB(255, 30, 107, 75)),
                  bottom:
                      BorderSide(color: const Color.fromARGB(255, 30, 107, 67)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big letter badge
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 61, 232, 144)
                          .withOpacity(0.12),
                      border: Border.all(
                          color: const Color.fromARGB(255, 79, 255, 167)
                              .withOpacity(0.5)),
                    ),
                    child: Text(
                      _letters[_selected!],
                      style: const TextStyle(
                        color: Color.fromARGB(255, 79, 255, 155),
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _acronyms[_selected!].toUpperCase(),
                          style: const TextStyle(
                            color: _cLetterGlow,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _descriptions[_selected!],
                          style: const TextStyle(
                            color: Color.fromARGB(255, 130, 200, 160),
                            fontSize: 16,
                            height: 1.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── STATUS BAR ──────────────────────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 14, 40, 27),
        border: Border.all(color: const Color.fromARGB(255, 12, 91, 46)),
      ),
      child: Row(
        children: [
          Container(width: 4, color: const Color.fromARGB(255, 61, 232, 127)),
          const SizedBox(width: 10),
          const Text('CREW READY',
              style:
                  TextStyle(color: _cTextSub, fontSize: 15, letterSpacing: 2)),
          const Spacer(),
          _BlinkingText('◉ SYSTEM NOMINAL', color: const Color(0xFF60DD80)),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ─── LAUNCH BUTTON ───────────────────────────────────────────────────────────
  Widget _buildLaunchButton() {
    return SizedBox(
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launched ? null : _launch,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _launched ? _cGreen.withOpacity(0.3) : _cGreen,
              border: Border.all(color: _cGreenBorder, width: 1.5),
              boxShadow: _launched
                  ? []
                  : [
                      BoxShadow(
                          color: _cGreen.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 4)),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: _cGreenFg, size: 20),
                const SizedBox(width: 12),
                Text(
                  _launched ? 'LAUNCHING...' : 'START RISK ASSESSMENT',
                  style: const TextStyle(
                    color: _cGreenFg,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HUD Row widget ───────────────────────────────────────────────────────────
class _HUDRow extends StatelessWidget {
  final String label, value;
  const _HUDRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 73,
          child: Text(label,
              style: const TextStyle(
                  color: Color.fromARGB(255, 5, 253, 141),
                  fontSize: 15,
                  letterSpacing: 1.6)),
        ),
        const Text('▸ ',
            style: TextStyle(
                color: Color.fromARGB(255, 36, 238, 144), fontSize: 15)),
        Text(value,
            style: const TextStyle(
                color: _cTextPrimary,
                fontSize: 15,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Pulsing dot ──────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
              const Color(0xFF30BB50), const Color(0xFF60FF80), _c.value),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF30FF50).withOpacity(_c.value * 0.8),
                blurRadius: 8)
          ],
        ),
      ),
    );
  }
}

// ─── Blinking text ────────────────────────────────────────────────────────────
class _BlinkingText extends StatefulWidget {
  final String text;
  final Color color;
  const _BlinkingText(this.text, {required this.color});
  @override
  State<_BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<_BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.5 + _c.value * 0.5,
        child: Text(widget.text,
            style: TextStyle(
                color: widget.color, fontSize: 15, letterSpacing: 1.8)),
      ),
    );
  }
}

// ─── Grid background painter ──────────────────────────────────────────────────
class _GridPainter extends StatelessWidget {
  final AnimationController controller;
  const _GridPainter({required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _GridCustomPainter(controller.value),
      ),
    );
  }
}

class _GridCustomPainter extends CustomPainter {
  final double t;
  _GridCustomPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 3, 51, 20).withOpacity(0.35)
      ..strokeWidth = 0.5;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Occasional flicker dot
    if (t > 0.7) {
      final dotPaint = Paint()
        ..color = const Color.fromARGB(255, 5, 62, 33).withOpacity(0.4);
      canvas.drawCircle(
        Offset((t * 173) % size.width, (t * 97) % size.height),
        1.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridCustomPainter old) => true;
}

// ─── Scanline painter ─────────────────────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  final double progress;
  final double height;
  _ScanlinePainter(this.progress, this.height);
  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * (size.height + 60) - 30;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color.fromARGB(255, 10, 83, 63).withOpacity(0.07),
          const Color.fromARGB(255, 10, 124, 91).withOpacity(0.12),
          const Color.fromARGB(255, 7, 77, 57).withOpacity(0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 30, size.width, 60));
    canvas.drawRect(Rect.fromLTWH(0, y - 30, size.width, 60), paint);
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}

// ─── Radar painter ────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 2;

    // Circles
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 3; i++) {
      circlePaint.color =
          const Color.fromARGB(255, 13, 74, 52).withOpacity(0.3);
      canvas.drawCircle(center, r * i / 3, circlePaint);
    }

    // Cross-hairs
    final linePaint = Paint()
      ..color = const Color.fromARGB(255, 13, 74, 52).withOpacity(0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(center.dx, center.dy - r),
        Offset(center.dx, center.dy + r), linePaint);
    canvas.drawLine(Offset(center.dx - r, center.dy),
        Offset(center.dx + r, center.dy), linePaint);

    // Sweep
    final sweepAngle = progress * 2 * math.pi;
    final sweepRect = Rect.fromCircle(center: center, radius: r);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          const Color.fromARGB(255, 15, 138, 60).withOpacity(0.6)
        ],
        tileMode: TileMode.clamp,
      ).createShader(sweepRect);
    canvas.drawCircle(center, r, sweepPaint);

    // Sweep line
    final sweepLinePaint = Paint()
      ..color = const Color.fromARGB(255, 11, 115, 62)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      center,
      Offset(center.dx + r * math.cos(sweepAngle),
          center.dy + r * math.sin(sweepAngle)),
      sweepLinePaint,
    );

    // Blip
    final blipAngle = progress * 2 * math.pi * 0.7;
    final blipDist = r * 0.55;
    final blipPos = Offset(
      center.dx + blipDist * math.cos(blipAngle),
      center.dy + blipDist * math.sin(blipAngle),
    );
    final blipBrightness =
        (math.sin((progress * 12) % math.pi)).clamp(0.0, 1.0);
    canvas.drawCircle(
      blipPos,
      2.5,
      Paint()
        ..color = const Color(0xFF60FF80).withOpacity(blipBrightness * 0.9),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

// ─── Tick painter (vertical axis decoration) ──────────────────────────────────
class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 12, 97, 49).withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    for (int i = 0; i <= 4; i++) {
      final y = i * size.height / 4;
      final hw = i == 0 || i == 4 ? 8.0 : 5.0;
      canvas.drawLine(
        Offset(size.width / 2 - hw, y),
        Offset(size.width / 2 + hw, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter _) => false;
}

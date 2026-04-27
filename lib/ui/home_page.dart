import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/ui/assessment_tab.dart';
import 'package:orm_risk_assessment/ui/history_tab.dart';
import 'package:orm_risk_assessment/ui/reference_tab.dart';

// ─── colour tokens (mirrors launch_page) ──────────────────────────────────────
const _cBackground  = Color(0xFF090C1A);
const _cSurface     = Color.fromARGB(255, 14, 40, 28);
const _cBorder      = Color.fromARGB(255, 30, 107, 57);
const _cBorderBright= Color.fromARGB(255, 45, 201, 89);
const _cAccent      = Color.fromARGB(255, 61, 232, 121);
const _cGreen       = Color(0xFF4A8C40);
const _cGreenFg     = Color(0xFFBBE0B0);
const _cTextPrimary = Color(0xFFDDE3FF);
const _cTextSub     = Color(0xFF6677CC);
const _cLetterLit   = Color.fromARGB(255, 79, 255, 146);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    AssessmentTab(),
    HistoryTab(),
    ReferenceTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: BoxDecoration(
            color: _cSurface,
            border: const Border(
              bottom: BorderSide(color: _cBorder, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _cAccent.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // ── Left: image + launch button ──────────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/launch');
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/left.png',
                          fit: BoxFit.contain,
                          height: 56,
                          width: 72,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _cAccent.withOpacity(0.10),
                            border: Border.all(color: _cBorderBright),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: _cLetterLit,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Centre: title ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ORM badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cAccent.withOpacity(0.13),
                            border: Border.all(color: _cBorderBright),
                          ),
                          child: const Text(
                            'ORM SHEET',
                            style: TextStyle(
                              color: _cLetterLit,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'OPERATIONAL RISK MANAGEMENT',
                          style: TextStyle(
                            color: _cTextSub,
                            fontSize: 8,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right: image ──────────────────────────────────────────
                  Image.asset(
                    'assets/images/right.png',
                    fit: BoxFit.contain,
                    height: 56,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cSurface,
          border: const Border(
            top: BorderSide(color: _cBorder, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: _cAccent.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _cLetterLit,
          unselectedItemColor: const Color(0xFF4A6060),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(letterSpacing: 1.2),
          items: [
            BottomNavigationBarItem(
              icon: _navIcon(Icons.security, 0),
              activeIcon: _navActiveIcon(Icons.security),
              label: 'RISK ASSESS',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(Icons.history, 1),
              activeIcon: _navActiveIcon(Icons.history),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(Icons.table_chart, 2),
              activeIcon: _navActiveIcon(Icons.table_chart),
              label: 'REFERENCE',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int idx) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Icon(icon, size: 22),
      );

  Widget _navActiveIcon(IconData icon) => Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _cAccent.withOpacity(0.12),
          border: Border.all(color: _cBorderBright.withOpacity(0.6)),
        ),
        child: Icon(icon, size: 18, color: _cLetterLit),
      );
}

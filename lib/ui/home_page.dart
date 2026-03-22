import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/ui/assessment_tab.dart';
import 'package:orm_risk_assessment/ui/history_tab.dart';
import 'package:orm_risk_assessment/ui/reference_tab.dart';

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
      appBar: AppBar(
        toolbarHeight: 150,
        leadingWidth: 150,
        title: const Text('ORM SHEET'),
        backgroundColor: const Color(0xFF4A6741),
        centerTitle: true,
        elevation: 0,
        // LEFT image
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // optional padding
          child: Image.asset(
            'assets/images/left.png',
            fit: BoxFit.contain,
          ),
        ),
        // RIGHT image
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0), // optional padding
            child: Image.asset(
              'assets/images/right.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF4A6741), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: const Color(0xFFB8D4A8),
          unselectedItemColor: const Color(0xFF888888),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.security),
              label: 'Risk Assessment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: 'Reference Tables',
            ),
          ],
        ),
      ),
    );
  }
}

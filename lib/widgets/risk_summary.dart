import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/utils/risk_calculator.dart';

class RiskSummary extends StatelessWidget {
  final String ormRisk;
  final String riskCategory;

  const RiskSummary({
    super.key,
    required this.ormRisk,
    required this.riskCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4A6741)),
        borderRadius: BorderRadius.zero,
        gradient: const LinearGradient(
          colors: [Color(0xFF1C3D2C), Color(0xFF0F2419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Assessment Summary',
            style: TextStyle(
              color: Color(0xFFD4E8C8),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ORM Risk Badge
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4A6741)),
                    borderRadius: BorderRadius.zero,
                    color: _getRiskColor(riskCategory),
                  ),
                  child: Text(
                    'ORM Risk: $ormRisk',
                    style: TextStyle(
                      color: _getRiskTextColor(riskCategory),
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4A6741)),
                    borderRadius: BorderRadius.zero,
                    color: _getRiskColor(riskCategory),
                  ),
                  child: Text(
                    'Risk Category: $riskCategory',
                    style: TextStyle(
                      color: _getRiskTextColor(riskCategory),
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Assessment Date
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4A6741)),
                    borderRadius: BorderRadius.zero,
                    color: const Color(0xFF2A2A2A),
                  ),
                  child: Text(
                    'Assessment Date: ${DateTime.now().toLocal().toIso8601String().split('T').first}',
                    style: const TextStyle(
                      color: Color(0xFFD4E8C8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String category) {
    switch (category) {
      case "Low risk":
        return const Color(0xFF2D5016);
      case "Moderate risk":
        return const Color(0xFF8B5A00);
      case "High risk":
        return const Color(0xFF8B4500);
      case "Very high risk":
        return const Color(0xFF8B1010);
      case "Extreme risk":
        return const Color(0xFF000000);
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  Color _getRiskTextColor(String category) {
    switch (category) {
      case "Low risk":
        return const Color(0xFFD4E8C8);
      case "Moderate risk":
        return const Color(0xFFFFE8C8);
      case "High risk":
        return const Color(0xFFFFE8C8);
      case "Very high risk":
        return const Color(0xFFFFCCCC);
      case "Extreme risk":
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF000000);
    }
  }
}

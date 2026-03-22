import 'package:orm_risk_assessment/models/mission_details.dart';
import 'package:orm_risk_assessment/models/risk_entry.dart';

class AssessmentHistory {
  final String id;
  final DateTime createdAt;
  final MissionDetails mission;
  final List<RiskEntry> entries;

  AssessmentHistory({
    required this.id,
    required this.createdAt,
    required this.mission,
    required this.entries,
  });

  factory AssessmentHistory.fromJson(Map<String, dynamic> json) {
    return AssessmentHistory(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      mission: MissionDetails.fromJson(json['mission'] as Map<String, dynamic>),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => RiskEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'mission': mission.toJson(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}

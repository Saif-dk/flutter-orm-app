import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orm_risk_assessment/models/assessment_history.dart';
import 'package:orm_risk_assessment/models/risk_entry.dart';
import 'package:orm_risk_assessment/models/mission_details.dart';

class DataService {
  static const String _missionDetailsKey = 'missionDetails';
  static const String _riskEntriesKey = 'riskEntries';
  static const String _historyKey = 'assessmentHistory';
  static const String _customHazardExamplesKey = 'customHazardExamples';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<MissionDetails> getMissionDetails() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_missionDetailsKey);

    if (json != null) {
      return MissionDetails.fromJson(jsonDecode(json));
    }

    // Return default mission details
    return MissionDetails(
      pilotName: '',
      pilotCode: '',
      secondPilotName: '',
      secondPilotCode: '',
      mechanicName: '',
      missionTime: '',
      missionType: '',
    );
  }

  Future<void> saveMissionDetails(MissionDetails details) async {
    final prefs = await _getPrefs();
    final json = jsonEncode(details.toJson());
    await prefs.setString(_missionDetailsKey, json);
  }

  Future<List<RiskEntry>> getRiskEntries() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_riskEntriesKey);

    if (json != null) {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => RiskEntry.fromJson(item)).toList();
    }

    return [];
  }

  Future<void> saveRiskEntries(List<RiskEntry> entries) async {
    final prefs = await _getPrefs();
    final json = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await prefs.setString(_riskEntriesKey, json);
  }

  Future<List<AssessmentHistory>> getAssessmentHistory() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_historyKey);

    if (json != null) {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => AssessmentHistory.fromJson(item)).toList()
        // sort newest first
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return [];
  }

  Future<void> saveAssessmentHistory(List<AssessmentHistory> history) async {
    final prefs = await _getPrefs();
    final json = jsonEncode(history.map((h) => h.toJson()).toList());
    await prefs.setString(_historyKey, json);
  }

  Future<void> addToAssessmentHistory(AssessmentHistory item) async {
    final history = await getAssessmentHistory();
    history.insert(0, item);
    await saveAssessmentHistory(history);
  }

  Future<Map<String, dynamic>> getCustomHazardExamples() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_customHazardExamplesKey);

    if (json != null) {
      return jsonDecode(json);
    }

    // Return default examples
    return {
      "PLANNING": [
        {"name": "Sufficient time for planning", "choices": []},
        {"name": "ANAMs AND NOAMS consultation", "choices": []},
        {"name": "Weight and balance", "choices": []},
        {"name": "Fuel considerations", "choices": []},
        {"name": "Fuel at the refueling stations available", "choices": []},
        {
          "name":
              "Coordination with Transit stations (food, rest, ground equipment, etc.)",
          "choices": []
        }
      ],
      "INTERFACE (HUMAN-MACHINE)": [
        {"name": "Cockpit setup", "choices": []},
        {"name": "Ergonomic", "choices": []},
        {
          "name": "Familiarity with the helicopter systems and displays",
          "choices": []
        },
        {
          "name": "Familiarity with specific equipment",
          "choices": ["Syntham 5000", "rotortuner", "other"]
        },
        {
          "name": "Familiarity with other systems",
          "choices": ["Foreflight", "SMS tracking", "other"]
        }
      ],
      "LEADERSHIP & SUPERVISION": [
        {"name": "Supervision", "choices": []},
        {"name": "Expectations", "choices": []},
        {"name": "Authority", "choices": []}
      ],
      "HUMAN FACTORS": [
        {"name": "Illness", "choices": []},
        {"name": "Medication", "choices": []},
        {"name": "Stress", "choices": []},
        {"name": "Alcohol", "choices": []},
        {"name": "Fatigue", "choices": []},
        {"name": "Emotion", "choices": []},
        {"name": " Recklessness/ Overconfidence", "choices": []}
      ],
      "COMMUNICATIONS": [
        {
          "name": "External communications",
          "choices": [
            "sufficient radios",
            "continuity of contact with ATC",
            "contact with other aircraft",
            "emergency call",
            "Missed radio calls",
            "unclear instruction"
          ]
        },
        {
          "name": "Internal communications",
          "choices": ["CRM", "standard calls", "priorities"]
        }
      ],
      "OPERATIONS / MISSION": [
        {
          "name": "Type of mission ",
          "choices": [
            "emergency procedures",
            "NVG",
            "formation",
            "terrain flight",
            "MTF",
            "other"
          ]
        },
        {"name": "High workload maneuvers", "choices": []},
        {"name": "Congested training areas", "choices": []},
        {
          "name": "Changing of the copilot/ student pilot in the working area",
          "choices": []
        }
      ],
      "TASK PROFICIENCY AND CURRENCY": [
        {"name": "PIC/ Instructor currency ", "choices": []},
        {"name": "Copilot Currency", "choices": []},
        {"name": "Student pilot skill level", "choices": []},
        {"name": "Experience/ recency of crewmembers", "choices": []},
        {"name": "Medical certificates", "choices": []},
        {"name": "Crewchief proficiency", "choices": []}
      ],
      "EQUIPMENT": [
        {
          "name": "Aircraft discrepancies, worn or faulty components",
          "choices": []
        },
        {"name": "Deferred actions", "choices": []},
        {
          "name": "Available flight hours until next scheduled maintenance",
          "choices": []
        },
        {"name": "Recurrent failure", "choices": []},
        {"name": "Aircraft equipment", "choices": []}
      ],
      "REGULATIONS / RISK DECISIONS": [
        {"name": "SOP deviations", "choices": []},
        {"name": "SPIns deviations", "choices": []},
        {"name": "Acceptance of unnecessary risk", "choices": []}
      ],
      "ENVIRONMENT": [
        {
          "name": "Weather",
          "choices": [
            "CB in the vicinity",
            "wind",
            "visibility",
            "ceiling",
            "temperature",
            "Haze",
            "turbulence",
            "other"
          ]
        },
        {
          "name": "Natural light",
          "choices": [
            "Position of the sun",
            "position of the moon",
            "phase of the moon"
          ]
        },
        {
          "name": "Landing zones",
          "choices": [
            "Natural and manmade Obstacles",
            "Downwash/ Brownout",
            "mud ground",
            "Birds",
            "Lazer hazard"
          ]
        }
      ]
    };
  }

  Future<void> saveCustomHazardExamples(Map<String, dynamic> examples) async {
    final prefs = await _getPrefs();
    final json = jsonEncode(examples);
    await prefs.setString(_customHazardExamplesKey, json);
  }
}

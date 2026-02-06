class RiskCalculator {
  static String calculateORMRisk(List<dynamic> riskEntries) {
    double maxScore = 0;

    for (var entry in riskEntries) {
      if (entry is Map<String, dynamic>) {
        final finalValue = (entry['finalRiskValue'] ?? 0.0) as double;
        if (finalValue > maxScore) {
          maxScore = finalValue;
        }
      }
    }

    return maxScore.toStringAsFixed(1);
  }

  static String getRiskCategory(String ormRisk) {
    double score;
    try {
      score = double.parse(ormRisk);
    } catch (e) {
      return 'No risks entered';
    }

    if (score >= 21 && score <= 25) return "Extreme risk";
    if (score >= 15 && score <= 20) return "Very high risk";
    if (score >= 10 && score <= 14) return "High risk";
    if (score >= 5 && score <= 9) return "Moderate risk";
    if (score >= 1 && score <= 4) return "Low risk";
    return "No risks entered";
  }

  static String getRiskCategoryColor(String category) {
    switch (category) {
      case "Low risk":
        return "#2D5016";
      case "Moderate risk":
        return "#8B5A00";
      case "High risk":
        return "#8B4500";
      case "Very high risk":
        return "#8B1010";
      case "Extreme risk":
        return "#000000";
      default:
        return "#FFFFFF";
    }
  }

  static double calculateRiskValue(
      int likelihood, int severity, double deduction) {
    return (likelihood * severity) - deduction;
  }

  static List<Map<String, dynamic>> getLikelihoodOptions() {
    return [
      {'value': 1, 'label': 'Very improbable'},
      {'value': 2, 'label': 'Improbable'},
      {'value': 3, 'label': 'Remote'},
      {'value': 4, 'label': 'Probable'},
      {'value': 5, 'label': 'Frequent'},
    ];
  }

  static List<Map<String, dynamic>> getSeverityOptions() {
    return [
      {'value': 1, 'label': 'Negligible'},
      {'value': 2, 'label': 'Minor'},
      {'value': 3, 'label': 'Major'},
      {'value': 4, 'label': 'Critical'},
      {'value': 5, 'label': 'Catastrophic'},
    ];
  }

  static List<String> getCategories() {
    return [
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
  }
}

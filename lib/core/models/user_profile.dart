class UserProfile {
  final String uid;
  final String name;
  // Personal details
  final DateTime dateOfBirth;
  final double currentWeight;
  final double height;
  final String gender;
  final double targetWeight;
  // Health information
  final List<String> allergies;
  final String otherAllergies;
  final List<String> dietaryRestrictions;
  final String otherDietaryRestrictions;
  final List<String> medicalConditions;
  final String otherMedicalConditions;
  // Goals & preferences
  final String primaryGoal;
  final String timeFrame;
  final String dietaryPreference;

  UserProfile({
    required this.uid,
    required this.name,
    required this.dateOfBirth,
    required this.currentWeight,
    required this.height,
    required this.gender,
    required this.targetWeight,
    required this.allergies,
    required this.otherAllergies,
    required this.dietaryRestrictions,
    required this.otherDietaryRestrictions,
    required this.medicalConditions,
    required this.otherMedicalConditions,
    required this.primaryGoal,
    required this.timeFrame,
    required this.dietaryPreference,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
      'currentWeight': currentWeight,
      'height': height,
      'gender': gender,
      'targetWeight': targetWeight,
      'allergies': allergies,
      'otherAllergies': otherAllergies,
      'dietaryRestrictions': dietaryRestrictions,
      'otherDietaryRestrictions': otherDietaryRestrictions,
      'medicalConditions': medicalConditions,
      'otherMedicalConditions': otherMedicalConditions,
      'primaryGoal': primaryGoal,
      'timeFrame': timeFrame,
      'dietaryPreference': dietaryPreference,
    };
  }
}

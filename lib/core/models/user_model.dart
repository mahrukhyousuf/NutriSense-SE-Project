class UserProfile {
  final String id;
  final String name;
  final double? weight;
  final double? height;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? calorieGoal;
  final double? proteinGoal;
  final double? carbGoal;
  final double? fatGoal;

  UserProfile({
    required this.id,
    required this.name,
    this.weight,
    this.height,
    this.dateOfBirth,
    this.gender,
    this.calorieGoal,
    this.proteinGoal,
    this.carbGoal,
    this.fatGoal,
  });

  // Calculate BMI if height and weight are available
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  // Calculate age if date of birth is available
  int? get age {
    if (dateOfBirth != null) {
      return DateTime.now().difference(dateOfBirth!).inDays ~/ 365;
    }
    return null;
  }
}

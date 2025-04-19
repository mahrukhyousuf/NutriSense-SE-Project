import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalsPreferencesScreen extends StatefulWidget {
  const GoalsPreferencesScreen({super.key});

  @override
  State<GoalsPreferencesScreen> createState() => _GoalsPreferencesScreenState();
}

class _GoalsPreferencesScreenState extends State<GoalsPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGoal;
  String? _selectedDietaryPreference;
  String? _selectedTimeFrame;
  bool _isSubmitting = false;

  final List<String> _goals = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Muscle',
    'Improve Health',
  ];

  final List<String> _dietaryPreferences = [
    'Asian',
    'Mediterranean',
    'Indian',
    'American',
    'Mexican',
    'Italian',
    'None',
  ];

  // Added time frame options for goal achievement
  final List<String> _timeFrames = [
    '1 month',
    '3 months',
    '6 months',
    '1 year',
    'Ongoing maintenance',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals & Preferences')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Your Goals',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Primary Goal Selection
                const Text(
                  'What is your primary goal?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Your Goal',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedGoal,
                  items:
                      _goals.map((goal) {
                        return DropdownMenuItem(value: goal, child: Text(goal));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGoal = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your goal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Time Frame Selection (Added for TC-037)
                const Text(
                  'What is your time frame for achieving this goal?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Your Time Frame',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTimeFrame,
                  items:
                      _timeFrames.map((timeFrame) {
                        return DropdownMenuItem(
                          value: timeFrame,
                          child: Text(timeFrame),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeFrame = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your time frame';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Dietary Preference
                const Text(
                  'What is your dietary preference?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Your Dietary Preference',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDietaryPreference,
                  items:
                      _dietaryPreferences.map((preference) {
                        return DropdownMenuItem(
                          value: preference,
                          child: Text(preference),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDietaryPreference = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your dietary preference';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Let's Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isSubmitting = true;
                                });

                                try {
                                  // 1. Get all stored data from SharedPreferences
                                  final prefs =
                                      await SharedPreferences.getInstance();

                                  // Personal details
                                  final dateOfBirthStr = prefs.getString(
                                    'dateOfBirth',
                                  );
                                  final dateOfBirth = DateTime.parse(
                                    dateOfBirthStr!,
                                  );
                                  final currentWeight =
                                      prefs.getDouble('currentWeight')!;
                                  final height = prefs.getDouble('height')!;
                                  final gender = prefs.getString('gender')!;
                                  final targetWeight =
                                      prefs.getDouble('targetWeight')!;
                                  final activityLevel =
                                      prefs.getString('activityLevel')!;

                                  // Health information
                                  final allergies =
                                      prefs.getStringList('allergies') ?? [];
                                  final otherAllergies =
                                      prefs.getString('otherAllergies') ?? '';
                                  final dietaryRestrictions =
                                      prefs.getStringList(
                                        'dietaryRestrictions',
                                      ) ??
                                      [];
                                  final otherDietaryRestrictions =
                                      prefs.getString(
                                        'otherDietaryRestrictions',
                                      ) ??
                                      '';
                                  final medicalConditions =
                                      prefs.getStringList(
                                        'medicalConditions',
                                      ) ??
                                      [];
                                  final otherMedicalConditions =
                                      prefs.getString(
                                        'otherMedicalConditions',
                                      ) ??
                                      '';

                                  // Goals & preferences (current screen)
                                  final primaryGoal = _selectedGoal!;
                                  final timeFrame = _selectedTimeFrame!;
                                  final dietaryPreference =
                                      _selectedDietaryPreference!;

                                  // 2. Get current user
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    throw Exception(
                                      'No authenticated user found',
                                    );
                                  }

                                  // First, get the name directly from the current user if available
                                  String userName = '';
                                  String userEmail = user.email ?? '';

                                  // 3. Then check Firestore for existing name as a backup
                                  final userDoc =
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .get();

                                  if (userDoc.exists) {
                                    final userData = userDoc.data();
                                    if (userData != null &&
                                        userData.containsKey('name') &&
                                        userData['name'] != null &&
                                        userData['name']
                                            .toString()
                                            .isNotEmpty) {
                                      userName = userData['name'];
                                      print(
                                        'Retrieved existing name from Firestore: $userName',
                                      );
                                    }
                                  }

                                  if (userName.isEmpty) {
                                    userName = user.displayName ?? 'User';
                                    print(
                                      'Using fallback name from Auth: $userName',
                                    );
                                  }

                                  // 4. Save all data to Firestore
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                        // Important user information
                                        'name': userName,
                                        'email': userEmail,

                                        // Personal details
                                        'dateOfBirth': Timestamp.fromDate(
                                          dateOfBirth,
                                        ),
                                        'currentWeight': currentWeight,
                                        'height': height,
                                        'gender': gender,
                                        'targetWeight': targetWeight,
                                        'activityLevel': activityLevel,

                                        // Health information
                                        'allergies': allergies,
                                        'otherAllergies': otherAllergies,
                                        'dietaryRestrictions':
                                            dietaryRestrictions,
                                        'otherDietaryRestrictions':
                                            otherDietaryRestrictions,
                                        'medicalConditions': medicalConditions,
                                        'otherMedicalConditions':
                                            otherMedicalConditions,

                                        // Goals & preferences
                                        'primaryGoal': primaryGoal,
                                        'timeFrame': timeFrame,
                                        'dietaryPreference': dietaryPreference,

                                        // Additional metadata
                                        'profileCompleted': true,
                                        'profileCompletedAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));

                                  // 5. Navigate to dashboard
                                  if (mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/dashboard',
                                    );
                                  }
                                } catch (e) {
                                  print('Error saving user data: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error saving your data: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isSubmitting = false;
                                    });
                                  }
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isSubmitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Let\'s Get Started',
                              style: TextStyle(fontSize: 16),
                            ),
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

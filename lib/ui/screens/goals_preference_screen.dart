import 'package:flutter/material.dart';

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
    'Other',
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // In a real app, you would save the user's goals and preferences here
                        // For now, proceed to the dashboard
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dateOfBirth;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  String? _selectedGender;
  String? _selectedActivityLevel;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];
  final List<String> _activityLevels = [
    'Sedentary (little or no exercise)',
    'Light (exercise 1-3 times/week)',
    'Moderate (exercise 3-5 times/week)',
    'Active (exercise 6-7 times/week)',
    'Very Active (intense exercise 6-7 times/week)',
  ];

  // Constants for validation
  static const double _minWeight = 20.0; // kg
  static const double _maxWeight = 300.0; // kg
  static const double _minHeight = 50.0; // cm
  static const double _maxHeight = 250.0; // cm
  static const double _minTargetWeight = 20.0; // kg
  static const double _maxTargetWeight = 300.0; // kg

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Let us get to know you better',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Date of Birth
                const Text(
                  'Date of Birth',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateOfBirth == null
                              ? 'Select Date'
                              : DateFormat(
                                'MMMM d, yyyy',
                              ).format(_dateOfBirth!),
                          style: TextStyle(
                            color:
                                _dateOfBirth == null
                                    ? Colors.grey
                                    : Colors.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current Weight
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Current Weight (kg)',
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                    helperText: 'Enter a valid number',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }

                    double? weight = double.tryParse(value);
                    if (weight == null) {
                      return 'Please enter a valid number';
                    }

                    if (weight <= 0) {
                      return 'Weight must be greater than 0';
                    }

                    if (weight < _minWeight) {
                      return 'Weight must be at least $_minWeight kg';
                    }

                    if (weight > _maxWeight) {
                      return 'Weight must be less than $_maxWeight kg';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Height
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                    suffixText: 'cm',
                    helperText: 'Enter a valid number',
                  ),

                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your height';
                    }

                    double? height = double.tryParse(value);
                    if (height == null) {
                      return 'Please enter a valid number';
                    }

                    if (height <= 0) {
                      return 'Height must be greater than 0';
                    }

                    if (height < _minHeight) {
                      return 'Height must be at least $_minHeight cm';
                    }

                    if (height > _maxHeight) {
                      return 'Height must be less than $_maxHeight cm';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedGender,
                  items:
                      _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Target Weight
                TextFormField(
                  controller: _targetWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Target Weight (kg)',
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                    helperText: 'Enter a valid number',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your target weight';
                    }

                    double? targetWeight = double.tryParse(value);
                    if (targetWeight == null) {
                      return 'Please enter a valid number';
                    }

                    if (targetWeight <= 0) {
                      return 'Target weight must be greater than 0';
                    }

                    if (targetWeight < _minTargetWeight) {
                      return 'Target weight must be at least $_minTargetWeight kg';
                    }

                    if (targetWeight > _maxTargetWeight) {
                      return 'Target weight must be less than $_maxTargetWeight kg';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Activity Level Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedActivityLevel,
                  items:
                      _activityLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityLevel = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your activity level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save Progress Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          _dateOfBirth != null) {
                        // In a real app, you would save the user's personal details here
                        // For now, proceed to the next screen
                        Navigator.pushNamed(context, '/health-info');
                      } else if (_dateOfBirth == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select your date of birth'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Save & Continue',
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

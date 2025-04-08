import 'package:flutter/material.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // None options
  bool _hasNoAllergies = false;
  bool _hasNoDietaryRestrictions = false;
  bool _hasNoMedicalConditions = false;

  // Allergies
  bool _hasPeanutAllergy = false;
  bool _hasGlutenAllergy = false;
  bool _hasDairyAllergy = false;
  final _otherAllergyController = TextEditingController();

  // Dietary Restrictions
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isHalal = false;
  bool _isKeto = false;
  final _otherDietaryRestrictionController = TextEditingController();

  // Medical Conditions
  bool _hasDiabetes = false;
  bool _hasPCOS = false;
  bool _hasLactoseIntolerance = false;
  bool _hasHighCholesterol = false;
  bool _hasIBS = false;
  final _otherMedicalConditionController = TextEditingController();

  // Regular expression for text field validation
  final RegExp _alphabeticRegExp = RegExp(r'^[a-zA-Z\s,.-]+$');

  // Check if at least one option is selected in each category
  bool get _isAllergySelectionValid =>
      _hasNoAllergies ||
      _hasPeanutAllergy ||
      _hasGlutenAllergy ||
      _hasDairyAllergy ||
      _otherAllergyController.text.isNotEmpty;

  bool get _isDietarySelectionValid =>
      _hasNoDietaryRestrictions ||
      _isVegetarian ||
      _isVegan ||
      _isHalal ||
      _isKeto ||
      _otherDietaryRestrictionController.text.isNotEmpty;

  bool get _isMedicalSelectionValid =>
      _hasNoMedicalConditions ||
      _hasDiabetes ||
      _hasPCOS ||
      _hasLactoseIntolerance ||
      _hasHighCholesterol ||
      _hasIBS ||
      _otherMedicalConditionController.text.isNotEmpty;

  // Check overall form validity
  bool get _isFormValid =>
      _isAllergySelectionValid &&
      _isDietarySelectionValid &&
      _isMedicalSelectionValid;

  // Update allergies when "None" is selected
  void _updateAllergies(bool value) {
    setState(() {
      _hasNoAllergies = value;
      if (value) {
        // Clear other allergies
        _hasPeanutAllergy = false;
        _hasGlutenAllergy = false;
        _hasDairyAllergy = false;
        _otherAllergyController.clear();
      }
    });
  }

  // Update dietary restrictions when "None" is selected
  void _updateDietaryRestrictions(bool value) {
    setState(() {
      _hasNoDietaryRestrictions = value;
      if (value) {
        // Clear other dietary restrictions
        _isVegetarian = false;
        _isVegan = false;
        _isHalal = false;
        _isKeto = false;
        _otherDietaryRestrictionController.clear();
      }
    });
  }

  // Update medical conditions when "None" is selected
  void _updateMedicalConditions(bool value) {
    setState(() {
      _hasNoMedicalConditions = value;
      if (value) {
        // Clear other medical conditions
        _hasDiabetes = false;
        _hasPCOS = false;
        _hasLactoseIntolerance = false;
        _hasHighCholesterol = false;
        _hasIBS = false;
        _otherMedicalConditionController.clear();
      }
    });
  }

  @override
  void dispose() {
    _otherAllergyController.dispose();
    _otherDietaryRestrictionController.dispose();
    _otherMedicalConditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Information')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health and Medical Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Allergies Section
                const Text(
                  'Do you have any of the following allergies?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // None option for allergies
                CheckboxListTile(
                  title: const Text('None'),
                  value: _hasNoAllergies,
                  onChanged: (value) {
                    if (value != null) {
                      _updateAllergies(value);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                // Display other options only if "None" is not selected
                if (!_hasNoAllergies) ...[
                  CheckboxListTile(
                    title: const Text('Peanuts'),
                    value: _hasPeanutAllergy,
                    onChanged: (value) {
                      setState(() {
                        _hasPeanutAllergy = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Gluten'),
                    value: _hasGlutenAllergy,
                    onChanged: (value) {
                      setState(() {
                        _hasGlutenAllergy = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Dairy'),
                    value: _hasDairyAllergy,
                    onChanged: (value) {
                      setState(() {
                        _hasDairyAllergy = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  // Other Allergies
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextFormField(
                      controller: _otherAllergyController,
                      decoration: const InputDecoration(
                        labelText: 'Other Allergies (if any)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Only letters, spaces, commas, periods, and hyphens allowed',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!_alphabeticRegExp.hasMatch(value)) {
                            return 'Only letters, spaces, and basic punctuation allowed';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],

                if (!_isAllergySelectionValid)
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Text(
                      'Please select at least one option or "None"',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                // Dietary Restrictions Section
                const Text(
                  'Do you have any of the following dietary restrictions?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // None option for dietary restrictions
                CheckboxListTile(
                  title: const Text('None'),
                  value: _hasNoDietaryRestrictions,
                  onChanged: (value) {
                    if (value != null) {
                      _updateDietaryRestrictions(value);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                // Display other options only if "None" is not selected
                if (!_hasNoDietaryRestrictions) ...[
                  CheckboxListTile(
                    title: const Text('Vegetarian'),
                    value: _isVegetarian,
                    onChanged: (value) {
                      setState(() {
                        _isVegetarian = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Vegan'),
                    value: _isVegan,
                    onChanged: (value) {
                      setState(() {
                        _isVegan = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Halal'),
                    value: _isHalal,
                    onChanged: (value) {
                      setState(() {
                        _isHalal = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Keto'),
                    value: _isKeto,
                    onChanged: (value) {
                      setState(() {
                        _isKeto = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  // Other Dietary Restrictions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextFormField(
                      controller: _otherDietaryRestrictionController,
                      decoration: const InputDecoration(
                        labelText: 'Other Dietary Restrictions (if any)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Only letters, spaces, commas, periods, and hyphens allowed',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!_alphabeticRegExp.hasMatch(value)) {
                            return 'Only letters, spaces, and basic punctuation allowed';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],

                if (!_isDietarySelectionValid)
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Text(
                      'Please select at least one option or "None"',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                // Medical Conditions Section
                const Text(
                  'Do you have any of the following medical conditions?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // None option for medical conditions
                CheckboxListTile(
                  title: const Text('None'),
                  value: _hasNoMedicalConditions,
                  onChanged: (value) {
                    if (value != null) {
                      _updateMedicalConditions(value);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                // Display other options only if "None" is not selected
                if (!_hasNoMedicalConditions) ...[
                  CheckboxListTile(
                    title: const Text('Diabetes'),
                    value: _hasDiabetes,
                    onChanged: (value) {
                      setState(() {
                        _hasDiabetes = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('PCOS'),
                    value: _hasPCOS,
                    onChanged: (value) {
                      setState(() {
                        _hasPCOS = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Lactose Intolerance'),
                    value: _hasLactoseIntolerance,
                    onChanged: (value) {
                      setState(() {
                        _hasLactoseIntolerance = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('High Cholesterol'),
                    value: _hasHighCholesterol,
                    onChanged: (value) {
                      setState(() {
                        _hasHighCholesterol = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('IBS (Irritable Bowel Syndrome)'),
                    value: _hasIBS,
                    onChanged: (value) {
                      setState(() {
                        _hasIBS = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  // Other Medical Conditions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextFormField(
                      controller: _otherMedicalConditionController,
                      decoration: const InputDecoration(
                        labelText: 'Other Medical Conditions (if any)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Only letters, spaces, commas, periods, and hyphens allowed',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!_alphabeticRegExp.hasMatch(value)) {
                            return 'Only letters, spaces, and basic punctuation allowed';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],

                if (!_isMedicalSelectionValid)
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Text(
                      'Please select at least one option or "None"',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 32),

                // Save Progress Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isFormValid
                            ? () {
                              if (_formKey.currentState!.validate()) {
                                // In a real app, you would save the user's health information here
                                // For now, proceed to the next screen
                                Navigator.pushNamed(
                                  context,
                                  '/goals-preferences',
                                );
                              }
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
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

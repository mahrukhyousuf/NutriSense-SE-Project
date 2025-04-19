import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Nutritional data
  int _dailyCalorieTarget = 0;
  int _caloriesConsumed = 0;
  double _carbsTarget = 0;
  double _proteinTarget = 0;
  double _fiberTarget = 0;
  double _carbsConsumed = 0;
  double _proteinConsumed = 0;
  double _fiberConsumed = 0;

  // Weight tracking
  List<FlSpot> _weightData = [];
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _weekDays = [];
  TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    _loadUserData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

    _weekDays = List.generate(7, (index) {
      return firstDayOfWeek.add(Duration(days: index));
    });

    _selectedDate = now;
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user document
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() ?? {};

          setState(() {
            _userData = data;
          });

          // Calculate nutritional needs
          _calculateNutritionalNeeds();

          // Load weight history
          await _loadWeightData(user.uid);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Separate method to load weight data
  Future<void> _loadWeightData(String userId) async {
    try {
      // Try to get weight entries from Firestore
      final weightCollection =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('weight_entries')
              .orderBy('date')
              .get();

      List<FlSpot> spots = [];

      if (weightCollection.docs.isNotEmpty) {
        // Load existing weight entries
        for (var doc in weightCollection.docs) {
          final data = doc.data();
          final timestamp = data['date'] as Timestamp;
          final weight =
              (data['weight'] is int)
                  ? (data['weight'] as int).toDouble()
                  : data['weight'] as double;

          spots.add(
            FlSpot(timestamp.millisecondsSinceEpoch.toDouble(), weight),
          );
        }

        setState(() {
          _weightData = spots;
        });
        print('Loaded ${spots.length} weight entries');
      } else {
        // If no weight history, create initial entry from user data
        if (_userData != null && _userData!.containsKey('currentWeight')) {
          final currentWeight =
              (_userData!['currentWeight'] is int)
                  ? (_userData!['currentWeight'] as int).toDouble()
                  : _userData!['currentWeight'] as double;

          final now = DateTime.now();

          // Add initial weight entry to Firestore
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('weight_entries')
              .add({'date': Timestamp.fromDate(now), 'weight': currentWeight});

          // Update local data
          setState(() {
            _weightData = [
              FlSpot(now.millisecondsSinceEpoch.toDouble(), currentWeight),
            ];
          });
          print('Created initial weight entry: $currentWeight kg');
        }
      }
    } catch (e) {
      print('Error loading weight data: $e');
    }
  }

  void _calculateNutritionalNeeds() {
    if (_userData == null) return;

    // Extract user data
    final gender = _userData!['gender'] ?? 'Male';
    final weight = _userData!['currentWeight'] ?? 70.0; // kg
    final height = _userData!['height'] ?? 170.0; // cm
    final dob = _userData!['dateOfBirth'] as Timestamp?;
    final activityLevel = _userData!['activityLevel'] ?? 'Moderate';
    final primaryGoal = _userData!['primaryGoal'] ?? 'Maintain Weight';

    // Calculate age
    int age = 25; // default
    if (dob != null) {
      final birthDate = dob.toDate();
      final now = DateTime.now();
      age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
    }

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Activity multiplier
    double activityMultiplier;
    switch (activityLevel) {
      case 'Sedentary (little or no exercise)':
        activityMultiplier = 1.2;
        break;
      case 'Light (exercise 1-3 times/week)':
        activityMultiplier = 1.375;
        break;
      case 'Moderate (exercise 3-5 times/week)':
        activityMultiplier = 1.55;
        break;
      case 'Active (exercise 6-7 times/week)':
        activityMultiplier = 1.725;
        break;
      case 'Very Active (intense exercise 6-7 times/week)':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55; // Moderate as default
    }

    // Calculate Total Daily Energy Expenditure (TDEE)
    double tdee = bmr * activityMultiplier;

    // Adjust based on goal
    switch (primaryGoal) {
      case 'Lose Weight':
        tdee -= 500; // Deficit of 500 calories
        break;
      case 'Gain Muscle':
        tdee += 300; // Surplus of 300 calories
        break;
      case 'Improve Health':
      case 'Maintain Weight':
      default:
        // No adjustment needed
        break;
    }

    // Set daily calorie target
    _dailyCalorieTarget = tdee.round();

    // Calculate macronutrient targets
    // Protein: 30% of calories, Carbs: 50%, Fats: 20%
    _proteinTarget =
        (_dailyCalorieTarget * 0.3 / 4)
            .round()
            .toDouble(); // 4 calories per gram
    _carbsTarget =
        (_dailyCalorieTarget * 0.5 / 4)
            .round()
            .toDouble(); // 4 calories per gram
    _fiberTarget = 25.0; // General recommendation
  }

  Future<void> _addWeightEntry(double weight) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final now = DateTime.now();

        // Add to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('weight_entries')
            .add({'date': Timestamp.fromDate(now), 'weight': weight});

        // Update local data immediately
        setState(() {
          _weightData.add(
            FlSpot(now.millisecondsSinceEpoch.toDouble(), weight),
          );
        });

        print('Added new weight entry: $weight kg');

        // Refresh UI to show updated graph
        setState(() {});
      } catch (e) {
        print('Error adding weight entry: $e');
      }
    }
  }

  String _calculateAge() {
    if (_userData == null || !_userData!.containsKey('dateOfBirth')) {
      return 'N/A';
    }

    try {
      final Timestamp timestamp = _userData!['dateOfBirth'];
      final DateTime dob = timestamp.toDate();
      final DateTime now = DateTime.now();

      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      return age.toString();
    } catch (e) {
      print('Error calculating age: $e');
      return 'N/A';
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  // Custom app bar with profile picture
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.green,
                    actions: [
                      // Settings button
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          // Navigate to settings screen
                        },
                      ),
                      // Profile picture
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            // Handle profile tap
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                _userData != null &&
                                        _userData!['profileImageUrl'] != null
                                    ? NetworkImage(
                                      _userData!['profileImageUrl'],
                                    )
                                    : null,
                            child:
                                _userData == null ||
                                        _userData!['profileImageUrl'] == null
                                    ? const Icon(
                                      Icons.person,
                                      color: Colors.green,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hi there,',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _userData != null && _userData!.containsKey('name')
                                ? _userData!['name']
                                : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Age display
                          Row(
                            children: [
                              const Icon(Icons.cake, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Age: ${_calculateAge()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Weekly calendar
                          _buildWeeklyCalendar(),

                          const SizedBox(height: 24),

                          // Daily Overview
                          const Text(
                            'Daily Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Calories left widget
                          _buildCaloriesWidget(
                            icon: Icons.restaurant,
                            title: 'Calories Left',
                            current: _dailyCalorieTarget - _caloriesConsumed,
                            target: _dailyCalorieTarget,
                            suffix: 'cal left',
                            color: Colors.green,
                          ),

                          const SizedBox(height: 16),

                          // Calories eaten widget
                          _buildCaloriesWidget(
                            icon: Icons.sentiment_satisfied_alt,
                            title: 'Calories Eaten',
                            current: _caloriesConsumed,
                            target: _dailyCalorieTarget,
                            suffix: 'cal eaten',
                            color: Colors.orange,
                          ),

                          const SizedBox(height: 24),

                          // Macros pie chart
                          _buildMacrosChart(),

                          const SizedBox(height: 16),

                          // Macros values
                          _buildMacroValues(),

                          const SizedBox(height: 32),

                          // Weight Tracker
                          const Text(
                            'Weight Tracker',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Weight graph
                          _buildWeightGraph(),

                          const SizedBox(height: 24),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to food log
                                  },
                                  icon: const Icon(Icons.restaurant_menu),
                                  label: const Text('Log Food'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to meal plan
                                  },
                                  icon: const Icon(Icons.calendar_today),
                                  label: const Text('Plan Your Meal'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _weekDays[index];
          final isSelected =
              day.day == _selectedDate.day &&
              day.month == _selectedDate.month &&
              day.year == _selectedDate.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber[200] : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey[700],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 4,
                      width: 4,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaloriesWidget({
    required IconData icon,
    required String title,
    required int current,
    required int target,
    required String suffix,
    required Color color,
  }) {
    final progress = target > 0 ? current / target : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$current/$target $suffix',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosChart() {
    // If all macros are 0, show equal parts for visualization
    final hasData =
        _carbsConsumed > 0 || _proteinConsumed > 0 || _fiberConsumed > 0;
    final total =
        hasData
            ? _carbsConsumed + _proteinConsumed + _fiberConsumed
            : 3; // Equal parts for empty chart

    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: hasData ? _carbsConsumed : 1,
                      color: Colors.lightBlue[200]!,
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: hasData ? _proteinConsumed : 1,
                      color: Colors.orange[200]!,
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: hasData ? _fiberConsumed : 1,
                      color: Colors.green[200]!,
                      title: '',
                      radius: 50,
                    ),
                  ],
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Macros',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMacroIndicator('Carbs', Colors.lightBlue[200]!),
              const SizedBox(height: 8),
              _buildMacroIndicator('Protein', Colors.orange[200]!),
              const SizedBox(height: 8),
              _buildMacroIndicator('Fiber', Colors.green[200]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildMacroValues() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroValueColumn(
            'Carbs',
            _carbsConsumed.toInt(),
            _carbsTarget.toInt(),
            'g',
            Colors.lightBlue[200]!,
          ),
          _buildMacroValueColumn(
            'Protein',
            _proteinConsumed.toInt(),
            _proteinTarget.toInt(),
            'g',
            Colors.orange[200]!,
          ),
          _buildMacroValueColumn(
            'Fiber',
            _fiberConsumed.toInt(),
            _fiberTarget.toInt(),
            'g',
            Colors.green[200]!,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroValueColumn(
    String label,
    int current,
    int target,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$current',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: '/$target$unit',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child:
                _weightData.isEmpty
                    ? const Center(child: Text('No weight data available'))
                    : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                            right: BorderSide.none,
                            top: BorderSide.none,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getWeightDataPoints(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.green,
                                  strokeWidth: 1,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: _getMinY(),
                        maxY: _getMaxY(),
                      ),
                    ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getLatestWeight(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Latest Weight',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () {
                    // Show dialog to add weight
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Add Weight Entry'),
                            content: TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final weightText =
                                      _weightController.text.trim();
                                  if (weightText.isNotEmpty) {
                                    final weight = double.tryParse(weightText);
                                    if (weight != null && weight > 0) {
                                      Navigator.pop(context);
                                      _addWeightEntry(weight);
                                      _weightController.clear();
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New helper method to prepare weight data points
  List<FlSpot> _getWeightDataPoints() {
    if (_weightData.isEmpty) return [];

    if (_weightData.length == 1) {
      // If only one point, create a horizontal line by adding another point
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      return [
        FlSpot(
          yesterday.millisecondsSinceEpoch.toDouble(),
          _weightData.first.y,
        ),
        _weightData.first,
        FlSpot(tomorrow.millisecondsSinceEpoch.toDouble(), _weightData.first.y),
      ];
    }

    // Sort by date (x value)
    _weightData.sort((a, b) => a.x.compareTo(b.x));

    return _weightData;
  }

  // Helper methods for the weight graph
  double _getMinY() {
    if (_weightData.isEmpty) return 0;
    double min = _weightData.first.y;
    for (var spot in _weightData) {
      if (spot.y < min) min = spot.y;
    }
    return (min * 0.95).floorToDouble(); // 5% lower than the minimum
  }

  double _getMaxY() {
    if (_weightData.isEmpty) return 100;
    double max = _weightData.first.y;
    for (var spot in _weightData) {
      if (spot.y > max) max = spot.y;
    }
    return (max * 1.05).ceilToDouble(); // 5% higher than the maximum
  }

  String _getLatestWeight() {
    if (_weightData.isEmpty) {
      return _userData != null && _userData!.containsKey('currentWeight')
          ? '${_userData!['currentWeight']} kg'
          : 'N/A';
    }

    // Find the most recent entry (highest x value)
    FlSpot latest = _weightData.first;
    for (var spot in _weightData) {
      if (spot.x > latest.x) latest = spot;
    }

    return '${latest.y.toStringAsFixed(1)} kg';
  }
}

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _isLoading = true;
//   Map<String, dynamic>? _userData;
//   List<FlSpot> _weightData = [];
//   TextEditingController _weightController = TextEditingController();

//   // Nutritional data
//   int _dailyCalorieTarget = 0;
//   int _caloriesConsumed = 0;
//   double _carbsTarget = 0;
//   double _proteinTarget = 0;
//   double _fiberTarget = 0;
//   double _carbsConsumed = 0;
//   double _proteinConsumed = 0;
//   double _fiberConsumed = 0;

//   // Weight tracking
//   List<FlSpot> _weightData = [];
//   DateTime _selectedDate = DateTime.now();
//   List<DateTime> _weekDays = [];

//   @override
//   void initState() {
//     super.initState();
//     _generateWeekDays();
//     _loadUserData();
//   }

//   void _generateWeekDays() {
//     final now = DateTime.now();
//     final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

//     _weekDays = List.generate(7, (index) {
//       return firstDayOfWeek.add(Duration(days: index));
//     });

//     _selectedDate = now;
//   }

//   Future<void> _loadUserData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         // Get user document
//         final userDoc =
//             await _firestore.collection('users').doc(user.uid).get();

//         if (userDoc.exists) {
//           final data = userDoc.data() ?? {};

//           setState(() {
//             _userData = data;
//           });

//           // Calculate nutritional needs
//           _calculateNutritionalNeeds();

//           // Generate initial weight data point
//           if (_userData != null && _userData!.containsKey('currentWeight')) {
//             final currentWeight = _userData!['currentWeight'];
//             final now = DateTime.now();

//             _weightData = [
//               FlSpot(
//                 now.millisecondsSinceEpoch.toDouble(),
//                 currentWeight.toDouble(),
//               ),
//             ];
//           }
//         }
//       }
//     } catch (e) {
//       print('Error loading user data: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _calculateNutritionalNeeds() {
//     if (_userData == null) return;

//     // Extract user data
//     final gender = _userData!['gender'] ?? 'Male';
//     final weight = _userData!['currentWeight'] ?? 70.0; // kg
//     final height = _userData!['height'] ?? 170.0; // cm
//     final dob = _userData!['dateOfBirth'] as Timestamp?;
//     final activityLevel = _userData!['activityLevel'] ?? 'Moderate';
//     final primaryGoal = _userData!['primaryGoal'] ?? 'Maintain Weight';

//     // Calculate age
//     int age = 25; // default
//     if (dob != null) {
//       final birthDate = dob.toDate();
//       final now = DateTime.now();
//       age = now.year - birthDate.year;
//       if (now.month < birthDate.month ||
//           (now.month == birthDate.month && now.day < birthDate.day)) {
//         age--;
//       }
//     }

//     // Calculate BMR using Mifflin-St Jeor Equation
//     double bmr;
//     if (gender == 'Male') {
//       bmr = 10 * weight + 6.25 * height - 5 * age + 5;
//     } else {
//       bmr = 10 * weight + 6.25 * height - 5 * age - 161;
//     }

//     // Activity multiplier
//     double activityMultiplier;
//     switch (activityLevel) {
//       case 'Sedentary (little or no exercise)':
//         activityMultiplier = 1.2;
//         break;
//       case 'Light (exercise 1-3 times/week)':
//         activityMultiplier = 1.375;
//         break;
//       case 'Moderate (exercise 3-5 times/week)':
//         activityMultiplier = 1.55;
//         break;
//       case 'Active (exercise 6-7 times/week)':
//         activityMultiplier = 1.725;
//         break;
//       case 'Very Active (intense exercise 6-7 times/week)':
//         activityMultiplier = 1.9;
//         break;
//       default:
//         activityMultiplier = 1.55; // Moderate as default
//     }

//     // Calculate Total Daily Energy Expenditure (TDEE)
//     double tdee = bmr * activityMultiplier;

//     // Adjust based on goal
//     switch (primaryGoal) {
//       case 'Lose Weight':
//         tdee -= 500; // Deficit of 500 calories
//         break;
//       case 'Gain Muscle':
//         tdee += 300; // Surplus of 300 calories
//         break;
//       case 'Improve Health':
//       case 'Maintain Weight':
//       default:
//         // No adjustment needed
//         break;
//     }

//     // Set daily calorie target
//     _dailyCalorieTarget = tdee.round();

//     // Calculate macronutrient targets
//     // Protein: 30% of calories, Carbs: 50%, Fats: 20%
//     _proteinTarget =
//         (_dailyCalorieTarget * 0.3 / 4)
//             .round()
//             .toDouble(); // 4 calories per gram
//     _carbsTarget =
//         (_dailyCalorieTarget * 0.5 / 4)
//             .round()
//             .toDouble(); // 4 calories per gram
//     _fiberTarget = 25.0; // General recommendation
//   }

//   String _calculateAge() {
//     if (_userData == null || !_userData!.containsKey('dateOfBirth')) {
//       return 'N/A';
//     }

//     try {
//       final Timestamp timestamp = _userData!['dateOfBirth'];
//       final DateTime dob = timestamp.toDate();
//       final DateTime now = DateTime.now();

//       int age = now.year - dob.year;
//       if (now.month < dob.month ||
//           (now.month == dob.month && now.day < dob.day)) {
//         age--;
//       }

//       return age.toString();
//     } catch (e) {
//       print('Error calculating age: $e');
//       return 'N/A';
//     }
//   }

//   Future<void> _signOut() async {
//     try {
//       await _auth.signOut();
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error signing out: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : CustomScrollView(
//                 slivers: [
//                   // Custom app bar with profile picture
//                   SliverAppBar(
//                     expandedHeight: 120.0,
//                     floating: false,
//                     pinned: true,
//                     backgroundColor: Colors.green,
//                     actions: [
//                       // Profile picture
//                       Padding(
//                         padding: const EdgeInsets.only(right: 16.0),
//                         child: GestureDetector(
//                           onTap: () {
//                             // Handle profile tap
//                           },
//                           child: CircleAvatar(
//                             radius: 20,
//                             backgroundColor: Colors.white,
//                             backgroundImage:
//                                 _userData != null &&
//                                         _userData!['profileImageUrl'] != null
//                                     ? NetworkImage(
//                                       _userData!['profileImageUrl'],
//                                     )
//                                     : null,
//                             child:
//                                 _userData == null ||
//                                         _userData!['profileImageUrl'] == null
//                                     ? const Icon(
//                                       Icons.person,
//                                       color: Colors.green,
//                                     )
//                                     : null,
//                           ),
//                         ),
//                       ),
//                     ],
//                     flexibleSpace: FlexibleSpaceBar(
//                       title: Column(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Hi there,',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             _userData != null && _userData!.containsKey('name')
//                                 ? _userData!['name']
//                                 : 'User',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 22,
//                             ),
//                           ),
//                         ],
//                       ),
//                       titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
//                     ),
//                   ),

//                   // Content
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Age display
//                           Row(
//                             children: [
//                               const Icon(Icons.cake, color: Colors.grey),
//                               const SizedBox(width: 8),
//                               Text(
//                                 'Age: ${_calculateAge()}',
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 24),

//                           // Weekly calendar
//                           _buildWeeklyCalendar(),

//                           const SizedBox(height: 24),

//                           // Daily Overview
//                           const Text(
//                             'Daily Overview',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           // Calories left widget
//                           _buildCaloriesWidget(
//                             icon: Icons.restaurant,
//                             title: 'Calories Left',
//                             current: _dailyCalorieTarget - _caloriesConsumed,
//                             target: _dailyCalorieTarget,
//                             suffix: 'cal left',
//                             color: Colors.green,
//                           ),

//                           const SizedBox(height: 16),

//                           // Calories eaten widget
//                           _buildCaloriesWidget(
//                             icon: Icons.sentiment_satisfied_alt,
//                             title: 'Calories Eaten',
//                             current: _caloriesConsumed,
//                             target: _dailyCalorieTarget,
//                             suffix: 'cal eaten',
//                             color: Colors.orange,
//                           ),

//                           const SizedBox(height: 24),

//                           // Macros pie chart
//                           _buildMacrosChart(),

//                           const SizedBox(height: 16),

//                           // Macros values
//                           _buildMacroValues(),

//                           const SizedBox(height: 32),

//                           // Weight Tracker
//                           const Text(
//                             'Weight Tracker',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           // Weight graph
//                           _buildWeightGraph(),

//                           const SizedBox(height: 24),

//                           // Action buttons
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton.icon(
//                                   onPressed: () {
//                                     // Navigate to food log
//                                   },
//                                   icon: const Icon(Icons.restaurant_menu),
//                                   label: const Text('Log Food'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: ElevatedButton.icon(
//                                   onPressed: () {
//                                     // Navigate to meal plan
//                                   },
//                                   icon: const Icon(Icons.calendar_today),
//                                   label: const Text('Plan Your Meal'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 16),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }

//   Widget _buildWeeklyCalendar() {
//     return Container(
//       height: 80,
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: 7,
//         itemBuilder: (context, index) {
//           final day = _weekDays[index];
//           final isSelected =
//               day.day == _selectedDate.day &&
//               day.month == _selectedDate.month &&
//               day.year == _selectedDate.year;

//           return GestureDetector(
//             onTap: () {
//               setState(() {
//                 _selectedDate = day;
//               });
//             },
//             child: Container(
//               width: 60,
//               margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//               decoration: BoxDecoration(
//                 color: isSelected ? Colors.amber[200] : Colors.transparent,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     DateFormat('E').format(day).toUpperCase(),
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: isSelected ? Colors.black : Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     day.day.toString(),
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight:
//                           isSelected ? FontWeight.bold : FontWeight.normal,
//                       color: isSelected ? Colors.black : Colors.grey[700],
//                     ),
//                   ),
//                   if (isSelected)
//                     Container(
//                       margin: const EdgeInsets.only(top: 4),
//                       height: 4,
//                       width: 4,
//                       decoration: const BoxDecoration(
//                         color: Colors.redAccent,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCaloriesWidget({
//     required IconData icon,
//     required String title,
//     required int current,
//     required int target,
//     required String suffix,
//     required Color color,
//   }) {
//     final progress = target > 0 ? current / target : 0.0;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 5,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           LinearProgressIndicator(
//             value: progress.clamp(0.0, 1.0),
//             backgroundColor: Colors.grey[200],
//             valueColor: AlwaysStoppedAnimation<Color>(color),
//             minHeight: 8,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '$current/$target $suffix',
//             style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMacrosChart() {
//     // If all macros are 0, show equal parts for visualization
//     final hasData =
//         _carbsConsumed > 0 || _proteinConsumed > 0 || _fiberConsumed > 0;
//     final total =
//         hasData
//             ? _carbsConsumed + _proteinConsumed + _fiberConsumed
//             : 3; // Equal parts for empty chart

//     return Container(
//       padding: const EdgeInsets.all(16),
//       height: 200,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 5,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: AspectRatio(
//               aspectRatio: 1,
//               child: PieChart(
//                 PieChartData(
//                   sections: [
//                     PieChartSectionData(
//                       value: hasData ? _carbsConsumed : 1,
//                       color: Colors.lightBlue[200]!,
//                       title: '',
//                       radius: 50,
//                     ),
//                     PieChartSectionData(
//                       value: hasData ? _proteinConsumed : 1,
//                       color: Colors.orange[200]!,
//                       title: '',
//                       radius: 50,
//                     ),
//                     PieChartSectionData(
//                       value: hasData ? _fiberConsumed : 1,
//                       color: Colors.green[200]!,
//                       title: '',
//                       radius: 50,
//                     ),
//                   ],
//                   sectionsSpace: 0,
//                   centerSpaceRadius: 40,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Macros',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               _buildMacroIndicator('Carbs', Colors.lightBlue[200]!),
//               const SizedBox(height: 8),
//               _buildMacroIndicator('Protein', Colors.orange[200]!),
//               const SizedBox(height: 8),
//               _buildMacroIndicator('Fiber', Colors.green[200]!),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMacroIndicator(String label, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 16,
//           height: 16,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 8),
//         Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//       ],
//     );
//   }

//   Widget _buildMacroValues() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 5,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildMacroValueColumn(
//             'Carbs',
//             _carbsConsumed.toInt(),
//             _carbsTarget.toInt(),
//             'g',
//             Colors.lightBlue[200]!,
//           ),
//           _buildMacroValueColumn(
//             'Protein',
//             _proteinConsumed.toInt(),
//             _proteinTarget.toInt(),
//             'g',
//             Colors.orange[200]!,
//           ),
//           _buildMacroValueColumn(
//             'Fiber',
//             _fiberConsumed.toInt(),
//             _fiberTarget.toInt(),
//             'g',
//             Colors.green[200]!,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMacroValueColumn(
//     String label,
//     int current,
//     int target,
//     String unit,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey[700],
//           ),
//         ),
//         const SizedBox(height: 8),
//         RichText(
//           text: TextSpan(
//             children: [
//               TextSpan(
//                 text: '$current',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//               TextSpan(
//                 text: '/$target$unit',
//                 style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWeightGraph() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       height: 200,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 5,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child:
//                 _weightData.isEmpty
//                     ? const Center(child: Text('No weight data available'))
//                     : LineChart(
//                       LineChartData(
//                         gridData: FlGridData(show: false),
//                         titlesData: FlTitlesData(show: false),
//                         borderData: FlBorderData(show: false),
//                         lineBarsData: [
//                           LineChartBarData(
//                             spots: _weightData,
//                             isCurved: true,
//                             color: Colors.green,
//                             barWidth: 4,
//                             isStrokeCapRound: true,
//                             dotData: FlDotData(show: true),
//                             belowBarData: BarAreaData(
//                               show: true,
//                               color: Colors.green.withOpacity(0.1),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   _userData != null && _userData!.containsKey('currentWeight')
//                       ? '${_userData!['currentWeight']} kg'
//                       : 'N/A',
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Latest Weight',
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 16),
//                 IconButton(
//                   onPressed: () {
//                     // Show dialog to add weight
//                   },
//                   icon: const Icon(
//                     Icons.add_circle,
//                     color: Colors.green,
//                     size: 36,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

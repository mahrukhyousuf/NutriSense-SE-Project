import 'package:flutter/material.dart';
import 'dart:math';

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen>
    with TickerProviderStateMixin {
  String? _selectedMeal;

  // Controllers for floating fruit animations
  late final List<AnimationController> _animationControllers = [];
  late final List<Animation<double>> _animations = [];

  // List of fruit emojis for background
  final List<String> _fruits = [
    '🍎',
    '🍌',
    '🍇',
    '🍊',
    '🍓',
    '🥝',
    '🍍',
    '🥭',
    '🍏',
    '🍐',
    '🍑',
    '🍒',
    '🍈',
    '🍉',
    '🍋',
    '🍅',
  ];
  final List<Offset> _fruitPositions = [];
  final List<double> _fruitSizes = [];
  final List<double> _fruitOpacities = [];

  @override
  void initState() {
    super.initState();

    // Create random positions for fruits
    final random = Random();
    // Create 20 fruits
    for (int i = 0; i < 20; i++) {
      // Initial positions (will be updated after layout)
      _fruitPositions.add(
        Offset(random.nextDouble() * 300, random.nextDouble() * 600),
      );

      // Random sizes for variety
      _fruitSizes.add(16 + random.nextDouble() * 20);

      // Random opacity for depth effect
      _fruitOpacities.add(0.1 + random.nextDouble() * 0.2);

      // Create animation controllers for each fruit
      final controller = AnimationController(
        duration: Duration(seconds: 3 + random.nextInt(7)),
        vsync: this,
      );

      // Create animations
      final animation = Tween<double>(begin: -15.0, end: 15.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: random.nextBool() ? Curves.easeInOut : Curves.elasticInOut,
        ),
      );

      _animationControllers.add(controller);
      _animations.add(animation);

      // Start the animations with different delays
      Future.delayed(Duration(milliseconds: random.nextInt(2000)), () {
        controller.repeat(reverse: true);
      });
    }

    // Get actual screen size after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
          // Update positions with actual screen dimensions
          for (int i = 0; i < _fruitPositions.length; i++) {
            _fruitPositions[i] = Offset(
              random.nextDouble() * size.width,
              random.nextDouble() * size.height,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Logging'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Floating fruits background
          ..._buildFloatingFruits(),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Food Logging',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Log your meals and snacks for today, and we\'ll help you track your nutrition, stay on top of your goals, and make healthier choices!',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),

                  // Select Meal heading
                  const Text(
                    'Select Meal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meal option cards
                  _buildMealCard(
                    title: 'Breakfast',
                    icon: Icons.breakfast_dining,
                    time: '10:00 AM',
                    mealType: 'Breakfast',
                  ),
                  const SizedBox(height: 12),

                  _buildMealCard(
                    title: 'Lunch',
                    icon: Icons.restaurant,
                    time: '01:00 PM',
                    mealType: 'Lunch',
                  ),
                  const SizedBox(height: 12),

                  _buildMealCard(
                    title: 'Dinner',
                    icon: Icons.dinner_dining,
                    time: '07:30 PM',
                    mealType: 'Dinner',
                  ),

                  const SizedBox(height: 32),

                  // Select Mode of Logging
                  const Text(
                    'Select Mode of Logging',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logging method buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLoggingMethodButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Barcode',
                        onTap: () => _navigateToLoggingMethod('barcode'),
                      ),
                      _buildLoggingMethodButton(
                        icon: Icons.search,
                        label: 'Search',
                        onTap: () => _navigateToLoggingMethod('search'),
                      ),
                      _buildLoggingMethodButton(
                        icon: Icons.edit_note,
                        label: 'Manual',
                        onTap: () => _navigateToLoggingMethod('manual'),
                      ),
                      _buildLoggingMethodButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () => _navigateToLoggingMethod('camera'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build floating fruits in the background
  List<Widget> _buildFloatingFruits() {
    List<Widget> fruitWidgets = [];

    for (int i = 0; i < _fruitPositions.length; i++) {
      final fruit = _fruits[i % _fruits.length];
      final position = _fruitPositions[i];
      final size = _fruitSizes[i];
      final opacity = _fruitOpacities[i];

      fruitWidgets.add(
        AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Positioned(
              left: position.dx + _animations[i].value,
              top: position.dy + _animations[i].value * 1.5,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: _animations[i].value * 0.05,
                  child: Text(fruit, style: TextStyle(fontSize: size)),
                ),
              ),
            );
          },
        ),
      );
    }

    return fruitWidgets;
  }

  // Method to build meal selection cards
  Widget _buildMealCard({
    required String title,
    required IconData icon,
    required String time,
    required String mealType,
  }) {
    final isSelected = _selectedMeal == mealType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMeal = mealType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.amber : Colors.white,
              ),
              child: Center(
                child: Icon(
                  isSelected ? Icons.check : Icons.add,
                  color: isSelected ? Colors.white : Colors.amber,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build logging method buttons
  Widget _buildLoggingMethodButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (_selectedMeal != null) {
          onTap();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a meal first'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Method to navigate to different logging methods
  void _navigateToLoggingMethod(String method) {
    // Here you would navigate to the appropriate screen
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $method logging for $_selectedMeal'),
        backgroundColor: Colors.green,
      ),
    );

    // You would navigate like this:
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggingMethodScreen(
          meal: _selectedMeal!,
          method: method,
        ),
      ),
    );
    */
  }
}

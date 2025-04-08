import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and App Name
                const Icon(
                  Icons.eco, // Placeholder for your logo
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  'NutriSense',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 30),

                // Tagline
                const Text(
                  'Track Your Nutrition Effortlessly',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Let's Get Started text
                const Text(
                  'Let\'s Get Started',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),

                // Are You New Here text
                const Text('Are You New Here?', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      foregroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Sign Up',
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

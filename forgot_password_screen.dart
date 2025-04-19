import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Handle password reset
  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Failed to send password reset email.';

        if (e.code == 'user-not-found') {
          errorMessage = 'No user found with this email address.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            _emailSent ? _buildEmailSentContent() : _buildForgotPasswordForm(),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset Password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter your email address and we will send you instructions to reset your password.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePasswordReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Email Sent!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'We have sent password reset instructions to ${_emailController.text}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Login', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text(
            'Didn\'t receive the email? Try again',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }
}
// version 1
// import 'package:flutter/material.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   bool _emailSent = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Forgot Password')),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child:
//             _emailSent ? _buildEmailSentContent() : _buildForgotPasswordForm(),
//       ),
//     );
//   }

//   Widget _buildForgotPasswordForm() {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Reset Password',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Enter your email address and we will send you instructions to reset your password.',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           const SizedBox(height: 24),
//           TextFormField(
//             controller: _emailController,
//             decoration: const InputDecoration(
//               labelText: 'Email',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.email),
//             ),
//             keyboardType: TextInputType.emailAddress,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter your email';
//               }
//               if (!RegExp(
//                 r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//               ).hasMatch(value)) {
//                 return 'Please enter a valid email';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 32),
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               onPressed: () {
//                 if (_formKey.currentState!.validate()) {
//                   // In a real app, you would send a password reset email here
//                   setState(() {
//                     _emailSent = true;
//                   });
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text(
//                 'Reset Password',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmailSentContent() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
//         const SizedBox(height: 24),
//         const Text(
//           'Email Sent!',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           'We have sent password reset instructions to ${_emailController.text}',
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 32),
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton(
//             onPressed: () {
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Back to Login', style: TextStyle(fontSize: 16)),
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextButton(
//           onPressed: () {
//             setState(() {
//               _emailSent = false;
//             });
//           },
//           child: const Text(
//             'Didn\'t receive the email? Try again',
//             style: TextStyle(color: Colors.green),
//           ),
//         ),
//       ],
//     );
//   }
// }

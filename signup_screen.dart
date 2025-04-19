import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Regular expressions for validation
  final RegExp _nameRegExp = RegExp(
    r'^[a-zA-Z\s]+$',
  ); // Only letters and spaces
  final RegExp _passwordStrengthRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
  );

  Future<void> _getImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return null;

    try {
      // Create a storage reference
      final storageRef = FirebaseStorage.instance.ref();
      final profileImageRef = storageRef.child('profile_images/$uid.jpg');

      // Upload file
      await profileImageRef.putFile(_profileImage!);

      // Get download URL
      final downloadUrl = await profileImageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Handle signup with Firebase
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with email and password
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        // Update display name
        try {
          await userCredential.user?.updateDisplayName(
            _nameController.text.trim(),
          );

          await userCredential.user?.reload();
          print('Display name updated to: ${userCredential.user?.displayName}');
        } catch (e) {
          print('Display name update error (ignoring): $e');
        }

        // Create user document in Firestore
        if (userCredential.user != null) {
          final String uid = userCredential.user!.uid;
          final String userName = _nameController.text.trim();

          print('Saving user name: $userName'); // Debug logging

          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'name': userName,
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'hasProfileImage': _profileImage != null,
          });

          // Upload profile image if selected
          if (_profileImage != null) {
            final imageUrl = await _uploadProfileImage(uid);
            if (imageUrl != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'profileImageUrl': imageUrl});
            }
          }
        }

        // Navigate to personal details screen on success
        if (mounted) {
          Navigator.pushNamed(context, '/personal-details');
        }
      } on FirebaseAuthException catch (e) {
        // Existing Firebase auth exception handling...
        String errorMessage = 'An error occurred during registration.';

        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        // Check if this is the PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails')) {
          // This error can be ignored, as the user was created successfully
          if (mounted) {
            Navigator.pushNamed(context, '/personal-details');
          }
        } else {
          // Handle other general errors
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } finally {
        // Reset loading state
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Password strength indicator
  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    // Define strength levels
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    // Map strength to color and text
    Color color = Colors.red;
    String text = 'Weak';

    if (strength >= 5) {
      color = Colors.green;
      text = 'Strong';
    } else if (strength >= 3) {
      color = Colors.orange;
      text = 'Medium';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create New Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Already Registered? Login here',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                // Profile Picture Selection
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                      child:
                          _profileImage == null
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _getImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Sign Up Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                // Full Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    helperText: 'Only letters and spaces allowed',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (!_nameRegExp.hasMatch(value)) {
                      return 'Name should only contain letters and spaces';
                    }
                    if (value.length > 50) {
                      return 'Name is too long (maximum 50 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email Field
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
                    if (value.length > 100) {
                      return 'Email is too long (maximum 100 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    helperText:
                        'Min 8 chars with letters, numbers & special chars',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    // Force rebuild for password strength indicator
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!_passwordStrengthRegExp.hasMatch(value)) {
                      return 'Password must include letters, numbers and special characters';
                    }
                    if (value.length > 50) {
                      return 'Password is too long (maximum 50 characters)';
                    }
                    return null;
                  },
                ),
                _buildPasswordStrengthIndicator(_passwordController.text),
                const SizedBox(height: 16),
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
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
// version 1
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   File? _profileImage;
//   final ImagePicker _picker = ImagePicker();

//   // Regular expressions for validation
//   final RegExp _nameRegExp = RegExp(
//     r'^[a-zA-Z\s]+$',
//   ); // Only letters and spaces
//   final RegExp _passwordStrengthRegExp = RegExp(
//     r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
//   );

//   Future<void> _getImage() async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       setState(() {
//         _profileImage = File(pickedFile.path);
//       });
//     }
//   }

//   // Password strength indicator
//   Widget _buildPasswordStrengthIndicator(String password) {
//     if (password.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     // Define strength levels
//     int strength = 0;
//     if (password.length >= 8) strength++;
//     if (password.contains(RegExp(r'[A-Z]'))) strength++;
//     if (password.contains(RegExp(r'[a-z]'))) strength++;
//     if (password.contains(RegExp(r'[0-9]'))) strength++;
//     if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

//     // Map strength to color and text
//     Color color = Colors.red;
//     String text = 'Weak';

//     if (strength >= 5) {
//       color = Colors.green;
//       text = 'Strong';
//     } else if (strength >= 3) {
//       color = Colors.orange;
//       text = 'Medium';
//     }

//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: LinearProgressIndicator(
//               value: strength / 5,
//               backgroundColor: Colors.grey[300],
//               valueColor: AlwaysStoppedAnimation<Color>(color),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(text, style: TextStyle(color: color)),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sign Up')),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Create New Account',
//                   style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pushReplacementNamed(context, '/login');
//                   },
//                   child: const Text(
//                     'Already Registered? Login here',
//                     style: TextStyle(color: Colors.green, fontSize: 14),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Profile Picture Selection
//                 Stack(
//                   alignment: Alignment.bottomRight,
//                   children: [
//                     CircleAvatar(
//                       radius: 60,
//                       backgroundColor: Colors.grey,
//                       backgroundImage:
//                           _profileImage != null
//                               ? FileImage(_profileImage!)
//                               : null,
//                       child:
//                           _profileImage == null
//                               ? const Icon(
//                                 Icons.person,
//                                 size: 60,
//                                 color: Colors.white,
//                               )
//                               : null,
//                     ),
//                     Positioned(
//                       right: 0,
//                       bottom: 0,
//                       child: InkWell(
//                         onTap: _getImage,
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: const BoxDecoration(
//                             color: Colors.green,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.camera_alt,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 30),
//                 const Text(
//                   'Sign Up Details',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 20),
//                 // Full Name Field
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Full Name',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.person),
//                     helperText: 'No special symbol allowed.',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your name';
//                     }

//                     if (!_nameRegExp.hasMatch(value)) {
//                       return 'Name should only contain letters and spaces';
//                     }

//                     if (value.length > 50) {
//                       return 'Name is too long (maximum 50 characters)';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 // Email Field
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.email),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!RegExp(
//                       r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                     ).hasMatch(value)) {
//                       return 'Please enter a valid email';
//                     }

//                     if (value.length > 100) {
//                       return 'Email is too long (maximum 100 characters)';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 // Password Field
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     border: const OutlineInputBorder(),
//                     prefixIcon: const Icon(Icons.lock),
//                     helperText:
//                         'Min 8 characters: only letters, numbers & special allowed',
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword
//                             ? Icons.visibility
//                             : Icons.visibility_off,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscurePassword = !_obscurePassword;
//                         });
//                       },
//                     ),
//                   ),
//                   onChanged: (value) {
//                     // Force rebuild for password strength indicator
//                     setState(() {});
//                   },
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a password';
//                     }
//                     if (value.length < 6) {
//                       return 'Password must be at least 8 characters';
//                     }

//                     if (!_passwordStrengthRegExp.hasMatch(value)) {
//                       return 'Password must include letters, numbers and special characters';
//                     }

//                     if (value.length > 50) {
//                       return 'Password is too long (maximum 50 characters)';
//                     }
//                     return null;
//                   },
//                 ),
//                 _buildPasswordStrengthIndicator(_passwordController.text),
//                 const SizedBox(height: 16),
//                 // Confirm Password Field
//                 TextFormField(
//                   controller: _confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: 'Confirm Password',
//                     border: const OutlineInputBorder(),
//                     prefixIcon: const Icon(Icons.lock),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword
//                             ? Icons.visibility
//                             : Icons.visibility_off,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscureConfirmPassword = !_obscureConfirmPassword;
//                         });
//                       },
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please confirm your password';
//                     }
//                     if (value != _passwordController.text) {
//                       return 'Passwords do not match';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       if (_formKey.currentState!.validate()) {
//                         // In a real app, you would create the user account here
//                         // For now, proceed to the onboarding process
//                         Navigator.pushNamed(context, '/personal-details');
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text(
//                       'Sign Up',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

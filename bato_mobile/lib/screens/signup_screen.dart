import 'package:flutter/material.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final UserService _userService = UserService();

  bool _isObscure = true;
  bool _isLoading = false;
  String _selectedGender = 'Male';
  String _selectedType = 'editor';

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _typeOptions = ['editor', 'viewer'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleMongoDBSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _userService.registerUser(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: _ageController.text.trim(),
          gender: _selectedGender,
          contactNumber: _contactNumberController.text.trim(),
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          address: _addressController.text.trim(),
          type: _selectedType,
        );

        if (!mounted) return;

        // Normalize response and look for token in common locations.
        final Map<String, dynamic> resp =
            // ignore: unnecessary_type_check
            response is Map<String, dynamic> ? response : {};
        final Map<String, dynamic>? userMap =
            resp['user'] is Map<String, dynamic> ? resp['user'] : null;

        final String? token =
            userMap?['token'] ??
            (resp['token'] is String ? resp['token'] as String : null);

        if (token != null && userMap != null) {
          // Save user data including token
          final Map<String, dynamic> toSave = Map<String, dynamic>.from(userMap);
          toSave['token'] = token;
          // Map _id to uid for consistency
          if (toSave['_id'] != null) {
            toSave['uid'] = toSave['_id'];
          }
          
          // Debug: Print the data being saved
          print('DEBUG: Saving user data: $toSave');
          
          await _userService.saveUserData(toSave);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MongoDB Registration successful! Welcome!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home screen when token is available
          Navigator.pushReplacementNamed(context, '/home');
        } else if (resp.isNotEmpty) {
          // Registration succeeded but no token returned: prompt to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MongoDB Registration successful! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        } else {
          // Unexpected empty response
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'MongoDB Registration failed: invalid server response',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'MongoDB Registration failed';
        
        // Parse specific error messages for better user feedback
        if (e.toString().contains('409') || e.toString().contains('duplicate')) {
          errorMessage = 'Email or username already exists. Please use different credentials.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid data provided. Please check your information.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.toString().contains('Failed to register user')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Registration failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleFirebaseSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final displayName =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

        await _userService.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: displayName,
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: _ageController.text.trim(),
          gender: _selectedGender,
          contactNumber: _contactNumberController.text.trim(),
          address: _addressController.text.trim(),
          type: _selectedType,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase Registration successful! Welcome!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'Firebase Registration failed';
        
        // Parse Firebase-specific error messages
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'An account with this email already exists.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak. Please choose a stronger password.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address format.';
        } else if (e.toString().contains('operation-not-allowed')) {
          errorMessage = 'Email/password accounts are not enabled.';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Registration failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
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
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // First Name and Last Name Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Age and Gender Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Age is required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid age';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: const Icon(Icons.people),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _genderOptions.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Gender is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Contact Number
                  TextFormField(
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Contact number is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.account_circle),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // User Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _typeOptions.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type.capitalize()),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Authentication Method Selection
                  const Text(
                    'Choose Authentication Method:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // MongoDB Sign Up Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleMongoDBSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.storage, color: Colors.white),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign Up with MongoDB',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Firebase Sign Up Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleFirebaseSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                    ),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign Up with Firebase',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Log In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

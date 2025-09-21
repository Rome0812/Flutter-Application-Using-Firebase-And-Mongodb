import 'package:flutter/material.dart';
import '../services/user_service.dart';
 
class LoginScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const LoginScreen({Key? key}) : super(key: key);
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();
 
  bool _isObscure = true;
  bool _isLoading = false;
 
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
 
  Future<void> _handleMongoDBLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _userService.loginUser(
          _emailController.text,
          _passwordController.text,
        );

        // Handle MongoDB login response structure
        final Map<String, dynamic> resp = response;
        final Map<String, dynamic>? userMap = resp['user'] is Map<String, dynamic> ? resp['user'] : null;
        final String? token = resp['token'] is String ? resp['token'] as String : null;

        if (userMap != null && token != null) {
          final Map<String, dynamic> toSave = Map<String, dynamic>.from(userMap);
          toSave['token'] = token;
          // Map _id to uid for consistency
          if (toSave['_id'] != null) {
            toSave['uid'] = toSave['_id'];
          }
          await _userService.saveUserData(toSave);
        } else {
          // Fallback to old method if response structure is different
          await _userService.saveUserData(response);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MongoDB Login successful!')),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'MongoDB Login failed';
        
        // Parse specific error messages for better user feedback
        if (e.toString().contains('404')) {
          errorMessage = 'User not found. Please check your email.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Invalid credentials. Please check your password.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'Account is inactive. Please contact support.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.toString().contains('Failed to load data')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
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

  Future<void> _handleFirebaseLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase Login successful!')),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'Firebase Login failed';
        
        // Parse Firebase-specific error messages
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email address.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address format.';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many failed attempts. Please try again later.';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
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
                    height: 120,
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
 
                  // Email Field
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
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
 
                  const SizedBox(height: 16),
 
                  // Password Field
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
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
 
                  const SizedBox(height: 24),
                  // Authentication Method Selection
                  const Text(
                    'Choose Authentication Method:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  

                  // MongoDB Login Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleMongoDBLogin,
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
                            'Login with MongoDB',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Firebase Login Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleFirebaseLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.local_fire_department, color: Colors.white),
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
                            'Login with Firebase',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
 
                  const SizedBox(height: 16),

                  // Forgot Password Link (Firebase only)
                  TextButton(
                    onPressed: () async {
                      if (_emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email first'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        await _userService.sendPasswordResetEmail(
                          email: _emailController.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent! Check your inbox.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to send reset email: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Forgot Password? (Firebase only)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account? '),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text('Sign Up'),
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
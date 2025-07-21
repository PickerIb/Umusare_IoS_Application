import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _showPassword = false;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    setState(() {
      _emailError = _passwordError = null;
    });
    bool valid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Email validation with specific messages
    if (email.isEmpty) {
      _emailError = 'Please enter your email address';
      valid = false;
    } else if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email)) {
      _emailError = 'Please enter a valid email address (e.g., user@example.com)';
      valid = false;
    }
    
    // Password validation with specific messages
    if (password.isEmpty) {
      _passwordError = 'Please enter your password';
      valid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters long';
      valid = false;
    }
    
    setState(() {});
    return valid;
  }

  // Real-time email validation with helpful messages
  void _validateEmail(String value) {
    setState(() {
      final email = value.trim();
      if (email.isEmpty) {
        _emailError = null; // Don't show error while typing
      } else if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  // Real-time password validation with helpful messages
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = null; // Don't show error while typing
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  void _onLogin() async {
    if (!_validateFields()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if account is locked
      if (_authService.isAccountLocked(email)) {
        final lockoutTime = _authService.getLockoutTimeRemaining(email);
        if (lockoutTime != null) {
          final minutes = lockoutTime.inMinutes;
          final seconds = lockoutTime.inSeconds % 60;
          throw Exception('Account temporarily locked due to too many failed attempts. Please try again in ${minutes}m ${seconds}s.');
        }
      }

      // First validate credentials before attempting login
      final validationResult = await _authService.validateUserCredentials(
        email: email,
        password: password,
      );

      if (!validationResult['isValid']) {
        // Set specific field errors if available
        if (validationResult['emailError'] != null) {
          setState(() {
            _emailError = validationResult['emailError'];
          });
        }
        if (validationResult['passwordError'] != null) {
          setState(() {
            _passwordError = validationResult['passwordError'];
          });
        }
        
        // Show appropriate error message
        String errorMessage = validationResult['error'];
        
        // Determine if both email and password are incorrect
        if (validationResult['emailError'] != null && validationResult['passwordError'] != null) {
          errorMessage = 'Email and password are incorrect.';
        } else if (validationResult['emailError'] != null) {
          errorMessage = 'Incorrect email.';
        } else if (validationResult['passwordError'] != null) {
          errorMessage = 'Incorrect password.';
        }
        
        throw Exception(errorMessage);
      }

      // Sign in user with Firestore
      await _authService.signInUser(
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Provide specific and user-friendly error messages
        if (errorMessage.contains('Incorrect email')) {
          errorMessage = 'Incorrect email.';
        } else if (errorMessage.contains('Incorrect password')) {
          errorMessage = 'Incorrect password.';
        } else if (errorMessage.contains('Email and password are incorrect')) {
          errorMessage = 'Email and password are incorrect.';
        } else if (errorMessage.contains('Email and password are required')) {
          errorMessage = 'Please enter both email and password.';
        } else if (errorMessage.contains('Email is required')) {
          errorMessage = 'Please enter your email address.';
        } else if (errorMessage.contains('Password is required')) {
          errorMessage = 'Please enter your password.';
        } else if (errorMessage.contains('Please enter a valid email address')) {
          errorMessage = 'Please enter a valid email address (e.g., user@example.com).';
        } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorMessage.contains('attempts remaining')) {
          errorMessage = errorMessage; // Keep the specific attempt count message
        } else if (errorMessage.contains('temporarily locked')) {
          errorMessage = errorMessage; // Keep the lockout message
        } else if (errorMessage.contains('Too many failed login attempts')) {
          errorMessage = 'Too many failed login attempts. Please try again in 1 minute.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 90,
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: theme.appBarTheme.foregroundColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue ordering the freshest fish!',
                      style: TextStyle(
                        color: theme.appBarTheme.foregroundColor?.withOpacity(0.7) ?? Colors.white70,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Email Field
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        hintText: 'Enter your email address',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        errorText: _emailError,
                        errorStyle: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onChanged: _validateEmail,
                    ),
                    const SizedBox(height: 18),
                    // Password Field
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        errorText: _passwordError,
                        errorStyle: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onChanged: _validatePassword,
                    ),
                    const SizedBox(height: 10),
                    // Divider to separate form from button
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white24,
                            thickness: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Icon(Icons.login, color: Colors.white38, size: 28),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white24,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 6,
                          shadowColor: Colors.black26,
                        ),
                        onPressed: _isLoading ? null : _onLogin,
                        child: _isLoading
                            ? SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Don't have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () => context.go('/signup'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
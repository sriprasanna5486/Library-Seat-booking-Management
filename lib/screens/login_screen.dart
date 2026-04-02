import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();

  bool _loading = false;

  void _login() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(
        email: _emailC.text.trim(),
        password: _passwordC.text,
      );
      if (!mounted) return;
      Fluttertoast.showToast(msg: "Logged in successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _resetPassword() async {
    final email = _emailC.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your email first.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email);
      Fluttertoast.showToast(msg: "Password reset email sent to $email");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //  Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Library.jpg', // your background image
              fit: BoxFit.fitHeight,
            ),
          ),

          //  Semi-transparent overlay
          // ignore: deprecated_member_use
          Container(color: Colors.black.withOpacity(0)),

          //  Login form card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Card(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.70),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Library Seat Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailC,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Enter valid email',
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordC,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : '6+ chars required',
                        ),
                        const SizedBox(height: 12),

                        //  Forgot Password button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.indigo),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Login Button
                        _loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    104,
                                    124,
                                    236,
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: const Text('Login'),
                              ),
                        const SizedBox(height: 12),

                        // Register Navigation
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Create a new account',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

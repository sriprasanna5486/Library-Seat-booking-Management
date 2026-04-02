import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _studentIdC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  final TextEditingController _confirmC = TextEditingController();

  bool _loading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordC.text != _confirmC.text) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    setState(() => _loading = true);
    try {
      print("Registering User ....");
      final user = await _authService.registerWithEmail(
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
        password: _passwordC.text,
        studentId: _studentIdC.text.trim(),
      );
      print(" Registration successful, UID: ${user?.uid}");

      Fluttertoast.showToast(
        msg: "Registered successfully! You will be logged in.",
      );
      // Firebase auth state changes will navigate to Home (AuthGate handles it).
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _studentIdC.dispose();
    _passwordC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameC,
                  decoration: InputDecoration(labelText: 'Full name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailC,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter valid email',
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _studentIdC,
                  decoration: InputDecoration(labelText: 'Student ID'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter student ID' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordC,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : '6+ chars required',
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _confirmC,
                  decoration: InputDecoration(labelText: 'Confirm password'),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : '6+ chars required',
                ),
                SizedBox(height: 20),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text('Register'),
                      ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  ),
                  child: Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/doctor_main_layout.dart';
import 'package:hosp_test/main_layout.dart';
import 'package:hosp_test/screens/doctor_home_page.dart';
import 'package:hosp_test/screens/forgot_password.dart';
import 'package:hosp_test/screens/user_home_page.dart';
import 'package:hosp_test/screens/success_booked.dart'; // Import ResetScreen
import 'package:hosp_test/utils/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String? _selectedRole; // Store selected role
  bool obsecurePass = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Login with Role-Based Navigation
  // Firebase Login with Role-Based Navigation
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a role: Doctor or Customer')),
        );
        return;
      }

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          await user.reload();
          user = _auth.currentUser; // Fetch the latest user state

          if (!user!.emailVerified) {
            await _auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please verify your email before logging in.')),
            );
            return;
          }

          // ✅ Determine the correct collection based on role
          String collection = _selectedRole == "Doctor" ? "doctors" : "users";

          // ✅ Fetch user data from the correct collection
          DocumentSnapshot userDoc =
              await _firestore.collection(collection).doc(user.uid).get();

          if (userDoc.exists) {
            String storedRole = userDoc['role'] ?? 'Customer';
            String status = userDoc['status'] ?? 'pending';

            if (_selectedRole != storedRole) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Incorrect role selected. Please try again.')),
              );
              return;
            }

            // ✅ If user is a doctor, check approval status
            if (storedRole == 'Doctor' && status != 'approved') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Your profile is under review. Please wait for admin approval.')),
              );
              await _auth.signOut();
              return;
            }

            // ✅ Navigate to the correct dashboard
            if (storedRole == 'Doctor') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const doctorMainLayout()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainLayout()),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('User data not found. Please contact support.')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';
        if (e.code == 'user-not-found') {
          message = 'No user found for this email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password. Try again.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          // Dropdown for selecting user type
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Login As'),
            items: ['Customer', 'Doctor']
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) => setState(() => _selectedRole = value!),
            validator: (value) => value == null ? 'Please select a role' : null,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.045),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: Config.primaryColor,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              labelText: 'Email',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.email_outlined),
              prefixIconColor: Config.primaryColor,
            ),
            validator: (value) => value!.isEmpty ? 'Enter a valid email' : null,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.045),

          // Password Field
          TextFormField(
            controller: _passController,
            obscureText: obsecurePass,
            cursorColor: Config.primaryColor,
            decoration: InputDecoration(
              hintText: 'Password',
              labelText: 'Password',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.lock_outline),
              prefixIconColor: Config.primaryColor,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obsecurePass = !obsecurePass;
                  });
                },
                icon: obsecurePass
                    ? const Icon(Icons.visibility_off_outlined,
                        color: Colors.black38)
                    : const Icon(Icons.visibility_outlined,
                        color: Config.primaryColor),
              ),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Enter a valid password' : null,
          ),

          // Forgot Password Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResetScreen()),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.025),

          // Login Button
          Button(
              width: double.infinity,
              title: 'Login',
              onPressed: _login,
              disable: false),
        ],
      ),
    );
  }
}

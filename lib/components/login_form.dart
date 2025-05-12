import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/doctor_main_layout.dart';
import 'package:hosp_test/main_layout.dart';
import 'package:hosp_test/screens/forgot_password.dart';
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
  bool _isLoading = false;

  String? _selectedRole;
  bool obsecurePass = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
        return;
      }

      setState(() => _isLoading = true); // Start loading

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          await user.reload();
          user = _auth.currentUser;

          if (!user!.emailVerified) {
            await _auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please verify your email before logging in.')),
            );
            setState(() => _isLoading = false); // Stop loading
            return;
          }

          DocumentSnapshot? userDoc;
          String? actualRole;
          String? status;

          DocumentSnapshot usersDoc =
              await _firestore.collection("users").doc(user.uid).get();
          DocumentSnapshot doctorsDoc =
              await _firestore.collection("doctors").doc(user.uid).get();

          if (usersDoc.exists) {
            userDoc = usersDoc;
            actualRole = "Customer";
          } else if (doctorsDoc.exists) {
            userDoc = doctorsDoc;
            actualRole = "Doctor";
            status = doctorsDoc["status"] ?? "pending";
          }

          if (userDoc == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data not found.')),
            );
            setState(() => _isLoading = false);
            return;
          }

          if (_selectedRole != actualRole) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Selected "$_selectedRole", but your role is "$actualRole".'),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          if (actualRole == 'Doctor' && status != 'approved') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile under review. Wait for approval.')),
            );
            await _auth.signOut();
            setState(() => _isLoading = false);
            return;
          }

          await _firestore
              .collection(actualRole == 'Doctor' ? 'doctors' : 'users')
              .doc(user.uid)
              .update({'lastLogin': FieldValue.serverTimestamp()});

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => actualRole == 'Doctor'
                      ? const doctorMainLayout()
                      : const MainLayout()),
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
      } finally {
        setState(() => _isLoading = false); // Stop loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
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
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: Config.primaryColor,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              prefixIconColor: Config.primaryColor,
            ),
            validator: (value) => value!.isEmpty ? 'Enter a valid email' : null,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.045),
          TextFormField(
            controller: _passController,
            obscureText: obsecurePass,
            cursorColor: Config.primaryColor,
            decoration: InputDecoration(
              hintText: 'Password',
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              prefixIconColor: Config.primaryColor,
              suffixIcon: IconButton(
                onPressed: () => setState(() => obsecurePass = !obsecurePass),
                icon: Icon(
                    obsecurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: obsecurePass ? Colors.black38 : Config.primaryColor),
              ),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Enter a valid password' : null,
          ),
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
          _isLoading
              ? const CircularProgressIndicator()
              : Button(
                  width: double.infinity,
                  title: 'Login',
                  onPressed: _login,
                  disable: false,
                ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/screens/email_link.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  bool obsecurePass = true;
  String? _selectedRole;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Sign-Up with Email Verification
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // Save user details in Firestore first
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole ?? 'Customer', // Default role if null
            'createdAt': FieldValue.serverTimestamp(),
            if (_selectedRole == 'Doctor') ...{
              'experience': _experienceController.text.trim(),
              'specialization': _specializationController.text.trim(),
              'clinicAddress': _clinicAddressController.text.trim(),
              'registrationNumber': _registrationNumberController.text.trim(),
            }
          });

          // Send email verification
          await user.sendEmailVerification();
          
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmailSent()),
        );

          // Sign out immediately to prevent unverified access
          await _auth.signOut();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
            decoration: const InputDecoration(labelText: 'Register As'),
            items: ['Customer', 'Doctor']
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) => setState(() => _selectedRole = value!),
            validator: (value) => value == null ? 'Please select a role' : null,
          ),
          Config.spaceMedium,
          TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (value) => value!.isEmpty ? 'Enter a valid email' : null),
          Config.spaceMedium,
          TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (value) => value!.isEmpty ? 'Enter a valid phone number' : null),
          Config.spaceMedium,
          if (_selectedRole == 'Doctor') ...[
            TextFormField(controller: _experienceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Experience (Years)')),
            Config.spaceMedium,
            TextFormField(controller: _specializationController, decoration: const InputDecoration(labelText: 'Specialization')),
            Config.spaceMedium,
            TextFormField(controller: _clinicAddressController, decoration: const InputDecoration(labelText: 'Clinic Address')),
            Config.spaceMedium,
            TextFormField(controller: _registrationNumberController, decoration: const InputDecoration(labelText: 'Medical Registration Number')),
            Config.spaceMedium,
          ],
          TextFormField(controller: _passController, obscureText: obsecurePass, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => obsecurePass = !obsecurePass), icon: Icon(obsecurePass ? Icons.visibility_off : Icons.visibility)))),
          SizedBox(height: MediaQuery.of(context).size.height * 0.065),
          Button(width: double.infinity, title: 'Sign Up', onPressed: _signUp, disable: false),
        ],
      ),
    );
  }
}
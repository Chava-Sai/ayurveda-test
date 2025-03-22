import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/screens/home_page.dart';
import 'package:hosp_test/utils/config.dart';

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
  final _otpController = TextEditingController();
  bool obsecurePass = true;
  bool otpSent = false;
  String verificationId = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Phone number validation
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number cannot be empty';
    }
    final phoneRegex = RegExp(r'^\d{10}$'); // Ensure exactly 10-digit phone number
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain at least one uppercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  // Send OTP
  Future<void> _sendOTP() async {
    if (_validatePhone(_phoneController.text) == null) {
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: "+91${_phoneController.text.trim()}", // Ensure country code
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number verified automatically')),
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.message}')),
            );
          },
          codeSent: (String verId, int? resendToken) {
            setState(() {
              verificationId = verId;
              otpSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent to your phone')),
            );
          },
          codeAutoRetrievalTimeout: (String verId) {
            verificationId = verId;
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Verify OTP and Register User
  Future<void> _verifyOTPAndSignUp() async {
    if (_formKey.currentState!.validate() && otpSent) {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: _otpController.text.trim(),
        );

        await _auth.signInWithCredential(credential);

        // Create user with email & password after OTP verification
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        print("User signed up: ${userCredential.user!.email}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User Registered Successfully!')),
        );

        // Navigate to HomePage after successful signup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
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
            validator: _validateEmail,
          ),
          Config.spaceMedium,
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            cursorColor: Config.primaryColor,
            decoration: const InputDecoration(
              hintText: 'Phone Number',
              labelText: 'Phone',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.phone),
              prefixIconColor: Config.primaryColor,
            ),
            validator: _validatePhone,
          ),
          Config.spaceMedium,
          otpSent
              ? TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  cursorColor: Config.primaryColor,
                  decoration: const InputDecoration(
                    hintText: 'Enter OTP',
                    labelText: 'OTP',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.lock_outline),
                    prefixIconColor: Config.primaryColor,
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter OTP' : null,
                )
              : Button(
                  width: double.infinity,
                  title: 'Send OTP',
                  onPressed: _sendOTP,
                  disable: false,
                ),
          Config.spaceMedium,
          TextFormField(
            controller: _passController,
            keyboardType: TextInputType.visiblePassword,
            cursorColor: Config.primaryColor,
            obscureText: obsecurePass,
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
                    ? const Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.black38,
                      )
                    : const Icon(
                        Icons.visibility_outlined,
                        color: Config.primaryColor,
                      ),
              ),
            ),
            validator: _validatePassword,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.065),
          Button(
            width: double.infinity,
            title: 'Sign Up',
            onPressed: _verifyOTPAndSignUp,
            disable: false,
          ),
        ],
      ),
    );
  }
}
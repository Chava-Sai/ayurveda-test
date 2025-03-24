import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  File? _aadharImage;
  File? _certificatePdf;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pick Aadhar Image
  Future<void> _pickAadharImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _aadharImage = File(pickedFile.path));
    }
  }

  // Pick Certificate PDF
  Future<void> _pickCertificatePdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _certificatePdf = File(result.files.single.path!));
    }
  }

  // Upload File to Firebase Storage
  Future<String?> _uploadFile(File file, String path) async {
    try {
      TaskSnapshot snapshot = await _storage.ref(path).putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  // Firebase Sign-Up with Email Verification & File Upload
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // Send verification email
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent. Please verify before logging in.')),
          );

          // **Upload Files & Get URLs**
          String? aadharUrl, certificateUrl;
          if (_aadharImage != null) {
            aadharUrl = await _uploadFile(_aadharImage!, "users/${user.uid}/aadhar.jpg");
          }
          if (_certificatePdf != null) {
            certificateUrl = await _uploadFile(_certificatePdf!, "users/${user.uid}/certificate.pdf");
          }

          // **Store User Details in Firestore**
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole ?? 'Customer',
            'createdAt': FieldValue.serverTimestamp(),
            if (_selectedRole == 'Doctor') ...{
              'experience': _experienceController.text.trim(),
              'specialization': _specializationController.text.trim(),
              'clinicAddress': _clinicAddressController.text.trim(),
              'registrationNumber': _registrationNumberController.text.trim(),
              'aadharUrl': aadharUrl, // Store Aadhar URL
              'certificateUrl': certificateUrl, // Store Certificate URL
              'status': 'pending' // Doctor verification pending
            }
          });

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
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAadharImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Upload Aadhar"),
                ),
                if (_aadharImage != null) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            Config.spaceMedium,
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickCertificatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Upload Certificate"),
                ),
                if (_certificatePdf != null) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            Config.spaceMedium,
          ],
          TextFormField(controller: _passController, obscureText: obsecurePass, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => obsecurePass = !obsecurePass), icon: Icon(obsecurePass ? Icons.visibility_off : Icons.visibility)))),
          SizedBox(height: MediaQuery.of(context).size.height * 0.045),
          Button(width: double.infinity, title: 'Sign Up', onPressed: _signUp, disable: false),
        ],
      ),
    );
  }
}
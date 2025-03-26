import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/screens/email_link.dart';
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  bool obsecurePass = true;
  String? _selectedRole;
  File? _profileImage;
  File? _aadharImage;
  File? _certificatePdf;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 📷 Pick Profile Image
  Future<void> _pickProfileImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  // 🆔 Pick Aadhar Image
  Future<void> _pickAadharImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _aadharImage = File(pickedFile.path));
    }
  }

  // 📜 Pick Certificate PDF
  Future<void> _pickCertificatePdf() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _certificatePdf = File(result.files.single.path!));
    }
  }

  // ⬆️ Upload File to Firebase Storage
  Future<String?> _uploadFile(File file, String path) async {
    try {
      TaskSnapshot snapshot = await _storage.ref(path).putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  // 🔐 Firebase Sign-Up with File Upload
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          await user.sendEmailVerification();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EmailSent()),
            );
          }

          String? profileUrl, aadharUrl, certificateUrl;
          if (_profileImage != null) {
            profileUrl = await _uploadFile(
                _profileImage!, "${_selectedRole}/${user.uid}/profile.jpg");
          }
          if (_aadharImage != null) {
            aadharUrl = await _uploadFile(
                _aadharImage!, "${_selectedRole}/${user.uid}/aadhar.jpg");
          }
          if (_certificatePdf != null) {
            certificateUrl = await _uploadFile(_certificatePdf!,
                "${_selectedRole}/${user.uid}/certificate.pdf");
          }

          String collection = _selectedRole == "Doctor" ? "doctors" : "users";

          await _firestore.collection(collection).doc(user.uid).set({
            'uid': user.uid,
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole,
            'profileUrl': profileUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'emailVerified': user.emailVerified,
            'status': _selectedRole == 'Doctor' ? 'pending' : 'approved',
            if (_selectedRole == 'Doctor') ...{
              'experience': _experienceController.text.trim(),
              'specialization': _specializationController.text.trim(),
              'clinicAddress': _clinicAddressController.text.trim(),
              'registrationNumber': _registrationNumberController.text.trim(),
              'aadharUrl': aadharUrl,
              'certificateUrl': certificateUrl,
            }
          });

          await _auth.signOut();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
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

          /// 🔄 Profile Image Picker
          Row(
            children: [
              /// 🔄 Profile Image Picker
              SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.86, // Ensures valid width
                child: ElevatedButton.icon(
                  onPressed: _pickProfileImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Upload Profile Photo"),
                ),
              ),
              if (_profileImage != null)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          Config.spaceMedium,

          TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  value!.isEmpty ? 'Enter a valid email' : null),
          Config.spaceMedium,
          TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value!.isEmpty ? 'Enter a valid name' : null),
          Config.spaceMedium,
          TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (value) =>
                  value!.isEmpty ? 'Enter a valid phone number' : null),
          Config.spaceMedium,

          if (_selectedRole == 'Doctor') ...[
            TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Experience (Years)')),
            Config.spaceMedium,
            TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(labelText: 'Specialization')),
            Config.spaceMedium,
            TextFormField(
                controller: _clinicAddressController,
                decoration: const InputDecoration(labelText: 'Clinic Address')),
            Config.spaceMedium,
            TextFormField(
                controller: _registrationNumberController,
                decoration: const InputDecoration(
                    labelText: 'Medical Registration Number')),
            Config.spaceMedium,
            Row(
              children: [
                /// 🔄 Aadhar Image Picker
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.86, // Ensures valid width
                  height: MediaQuery.of(context).size.height * 0.06,
                  child: ElevatedButton.icon(
                    onPressed: _pickAadharImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Upload Aadhar"),
                  ),
                ),
                if (_aadharImage != null)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            Config.spaceMedium,
            Row(
              children: [
                /// 📜 Certificate PDF Picker
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.86, // Ensures valid width
                  height: MediaQuery.of(context).size.height * 0.06,
                  child: ElevatedButton.icon(
                    onPressed: _pickCertificatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Upload Certificate"),
                  ),
                ),
                if (_certificatePdf != null)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            Config.spaceMedium,
          ],

          TextFormField(
              controller: _passController,
              obscureText: obsecurePass,
              decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obsecurePass = !obsecurePass),
                      icon: Icon(obsecurePass
                          ? Icons.visibility_off
                          : Icons.visibility)))),
          SizedBox(height: MediaQuery.of(context).size.height * 0.045),
          Button(
              width: double.infinity,
              title: 'Sign Up',
              onPressed: _signUp,
              disable: false),
        ],
      ),
    );
  }
}

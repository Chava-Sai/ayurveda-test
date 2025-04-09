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
  final _locationController = TextEditingController();
  final _feeController = TextEditingController();
  final _aboutController = TextEditingController();
  final _degreeController = TextEditingController();
  final _slotTimeController = TextEditingController();
  // final _languageController = TextEditingController();
  final _stateController = TextEditingController();
  bool obsecurePass = true;
  String? _selectedRole;
  File? _profileImage;
  File? _aadharImage;
  File? _degreePdf;
  File? _registrationCertificatePdf;

  List<String> _selectedLanguages = [];
  final List<String> _allLanguages = [
    'Telugu',
    'Hindi',
    'English',
  ];

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        _selectedLanguages.add(language);
      }
    });
  }

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
  Future<void> _degreeCertificatePdf() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _degreePdf = File(result.files.single.path!));
    }
  }

  Future<void> _pickregistrationCertificatePdf() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(
          () => _registrationCertificatePdf = File(result.files.single.path!));
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

          String? profileUrl,
              aadharUrl,
              degreeCertificateUrl,
              registrationCertificateUrl;
          if (_profileImage != null) {
            profileUrl = await _uploadFile(
                _profileImage!, "${_selectedRole}/${user.uid}/profile.jpg");
          }
          if (_aadharImage != null) {
            aadharUrl = await _uploadFile(
                _aadharImage!, "${_selectedRole}/${user.uid}/aadhar.jpg");
          }
          if (_degreePdf != null) {
            degreeCertificateUrl = await _uploadFile(_degreePdf!,
                "${_selectedRole}/${user.uid}/degreeCertificate.pdf");
          }
          if (_registrationCertificatePdf != null) {
            registrationCertificateUrl = await _uploadFile(
                _registrationCertificatePdf!,
                "${_selectedRole}/${user.uid}/registrationCertificate.pdf");
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
              'degree': _degreeController.text.trim(),
              'experience': _experienceController.text.trim(),
              'specialization': _specializationController.text.trim(),
              'slotTime': _slotTimeController.text.trim(),
              'language': _selectedLanguages,
              'location': _locationController.text.trim(),
              'about': _aboutController.text.trim(),
              'state': _stateController.text.trim(),
              'fee': _feeController.text.trim(),
              'aadharUrl': aadharUrl,
              'degreeCertificateUrl': degreeCertificateUrl,
              'registrationCertificateUrl': registrationCertificateUrl,
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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final formattedTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return TimeOfDay.fromDateTime(formattedTime).format(context);
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
                height: MediaQuery.of(context).size.height * 0.06,
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
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: (value) =>
                  value!.isEmpty ? 'Enter a valid phone number' : null),
          Config.spaceMedium,

          if (_selectedRole == 'Doctor') ...[
            TextFormField(
              controller: _aboutController,
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'About Doctor',
                hintText:
                    'Write a short paragraph about yourself (max 300 characters)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter something about the doctor';
                }
                if (value.length > 300) {
                  return 'Please limit to 300 characters';
                }
                return null;
              },
            ),
            TextFormField(
                controller: _degreeController,
                decoration: const InputDecoration(labelText: 'Degree')),
            Config.spaceMedium,
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
              controller: _slotTimeController,
              decoration: const InputDecoration(
                labelText: 'Slot Time',
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true, // Prevent manual input
              onTap: () async {
                TimeOfDay? startTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (startTime != null) {
                  TimeOfDay? endTime = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );

                  if (endTime != null) {
                    setState(() {
                      _slotTimeController.text =
                          "${_formatTime(startTime)} to ${_formatTime(endTime)}";
                    });
                  }
                }
              },
            ),
            Config.spaceMedium,
            const Text(
              'Select Languages You Speak:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Config.spaceSmall,
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _allLanguages.map((language) {
                return FilterChip(
                  label: Text(language),
                  selected: _selectedLanguages.contains(language),
                  onSelected: (selected) => _toggleLanguage(language),
                  selectedColor: Config.primaryColor,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            Config.spaceMedium,
            TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location')),
            Config.spaceMedium,
            DropdownButtonFormField<String>(
              value: _stateController.text.isNotEmpty
                  ? _stateController.text
                  : null,
              decoration: const InputDecoration(labelText: 'State'),
              items: [
                'Andhra Pradesh',
                'Arunachal Pradesh',
                'Assam',
                'Bihar',
                'Chhattisgarh',
                'Goa',
                'Gujarat',
                'Haryana',
                'Himachal Pradesh',
                'Jharkhand',
                'Karnataka',
                'Kerala',
                'Madhya Pradesh',
                'Maharashtra',
                'Manipur',
                'Meghalaya',
                'Mizoram',
                'Nagaland',
                'Odisha',
                'Punjab',
                'Rajasthan',
                'Sikkim',
                'Tamil Nadu',
                'Telangana',
                'Tripura',
                'Uttar Pradesh',
                'Uttarakhand',
                'West Bengal'
              ]
                  .map((lang) =>
                      DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _stateController.text = value!;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a State' : null,
            ),
            Config.spaceMedium,
            TextFormField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fee',
                prefixText: 'Rs. ', // Display Rs. in front
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the fee';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
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
                    onPressed: _degreeCertificatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Upload Degree Certificate"),
                  ),
                ),
                if (_degreePdf != null)
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
                    onPressed: _pickregistrationCertificatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Upload Registration Certificate"),
                  ),
                ),
                if (_registrationCertificatePdf != null)
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

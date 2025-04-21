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
  bool _certificateError = true;

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

          // 🌟 Generate unique doctorId like KH01, KH02...
          String? doctorId;
          if (_selectedRole == 'Doctor') {
            final counterRef =
                _firestore.collection('metadata').doc('doctor_counter');
            final counterSnap = await counterRef.get();

            int currentCount = 0;
            if (counterSnap.exists &&
                counterSnap.data()!.containsKey('count')) {
              currentCount = counterSnap['count'];
            }

            currentCount += 1;
            doctorId = 'KH${currentCount.toString().padLeft(2, '0')}';

            await counterRef.set({'count': currentCount}); // ✅ Update counter
          }

          // ⬆️ Uploads
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
              "${_selectedRole}/${user.uid}/registrationCertificate.pdf",
            );
          }

          // 🔥 Save user/doctor to Firestore
          String collection = _selectedRole == "Doctor" ? "doctors" : "users";

          await _firestore.collection(collection).doc(user.uid).set({
            'uid': user.uid,
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole,
            'profileUrl': profileUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'status': _selectedRole == 'Doctor' ? 'pending' : 'approved',
            if (_selectedRole == 'Doctor') ...{
              'doctorId': doctorId, // ✅ Custom ID stored here
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
          FormField<File>(
            validator: (value) {
              if (_profileImage == null) {
                return 'Please upload a profile photo';
              }
              return null;
            },
            builder: (fieldState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.81,
                      height: MediaQuery.of(context).size.height * 0.06,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _pickProfileImage();
                          if (_profileImage != null) {
                            fieldState
                                .didChange(_profileImage); // ✅ Clear error

                            // 🔄 Optional revalidate the entire form
                            if (_formKey.currentState != null) {
                              _formKey.currentState!.validate();
                            }
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Upload Profile Photo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              fieldState.hasError ? Colors.redAccent : null,
                        ),
                      ),
                    ),
                    if (_profileImage != null)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                if (fieldState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      fieldState.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          Config.spaceMedium,

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a valid email'
                : null,
            onChanged: (value) {
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            },
          ),
          Config.spaceMedium,

          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a valid name'
                : null,
            onChanged: (value) {
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            },
          ),
          Config.spaceMedium,

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a valid phone number'
                : null,
            onChanged: (value) {
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            },
          ),

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
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter something about the doctor';
                }
                if (value.trim().length > 300) {
                  return 'Please limit to 300 characters';
                }
                return null;
              },
              onChanged: (value) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!
                      .validate(); // Triggers re-validation as user types
                }
              },
            ),
            Config.spaceMedium,
            TextFormField(
              controller: _degreeController,
              decoration: const InputDecoration(labelText: 'Degree'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a valid Degree'
                  : null,
              onChanged: (value) {
                // Triggers rebuild and clears error once the user types
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
            ),
            Config.spaceMedium,
            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Experience (Years)'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a valid Experience'
                  : null,
              onChanged: (value) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
            ),
            Config.spaceMedium,
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(labelText: 'Specialization'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a valid Specialization'
                  : null,
              onChanged: (value) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
            ),
            Config.spaceMedium,
            TextFormField(
              controller: _slotTimeController,
              decoration: const InputDecoration(
                labelText: 'Slot Time',
                suffixIcon: Icon(Icons.access_time),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a valid Slot Time'
                  : null,
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

                    // Trigger re-validation after setting the slot time
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  }
                }
              },
            ),
            Config.spaceMedium,
            FormField<List<String>>(
              initialValue: _selectedLanguages,
              validator: (value) {
                if (_selectedLanguages.isEmpty) {
                  return 'Please select at least one language';
                }
                return null;
              },
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: const Text(
                      'Select Languages You Speak:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Config.spaceSmall,
                  Center(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _allLanguages.map((language) {
                        return FilterChip(
                          label: Text(language),
                          selected: _selectedLanguages.contains(language),
                          onSelected: (selected) {
                            _toggleLanguage(language);
                            state.didChange(
                                _selectedLanguages); // update form state

                            // Immediately validate on selection
                            if (_formKey.currentState != null) {
                              _formKey.currentState!.validate();
                            }
                          },
                          selectedColor: Config.primaryColor,
                          checkmarkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Config.spaceMedium,
            // LOCATION
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (value) =>
                  value!.isEmpty ? 'Enter a valid Location' : null,
              onChanged: (_) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
            ),
            Config.spaceMedium,

// STATE (Dropdown)
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
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
              validator: (value) =>
                  value == null ? 'Please select a State' : null,
            ),
            Config.spaceMedium,

// FEE
            TextFormField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fee',
                prefixText: 'Rs. ',
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
              onChanged: (_) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
            ),

            Config.spaceMedium,
            FormField<File>(
              validator: (value) {
                if (_aadharImage == null) {
                  return 'Please upload your Aadhar image';
                }
                return null;
              },
              builder: (fieldState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.81,
                        height: MediaQuery.of(context).size.height * 0.06,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final pickedFile = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                _aadharImage = File(pickedFile.path);
                              });
                              fieldState
                                  .didChange(_aadharImage); // ✅ Sync form state

                              // Optionally trigger form validation again
                              if (_formKey.currentState != null) {
                                _formKey.currentState!.validate();
                              }
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text("Upload Aadhar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                fieldState.hasError ? Colors.redAccent : null,
                          ),
                        ),
                      ),
                      if (_aadharImage != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  if (fieldState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        fieldState.errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Config.spaceMedium,
            FormField<File>(
              validator: (value) {
                if (_degreePdf == null) {
                  return 'This document is required.';
                }
                return null;
              },
              builder: (fieldState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormField<File>(
                    validator: (file) {
                      if (_degreePdf == null) {
                        return 'This document is required.';
                      }
                      return null;
                    },
                    builder: (fieldState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.81,
                              height: MediaQuery.of(context).size.height * 0.06,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _degreeCertificatePdf();
                                  fieldState.didChange(
                                      _degreePdf); // update form state

                                  if (_formKey.currentState != null) {
                                    _formKey.currentState!
                                        .validate(); // trigger validation
                                  }
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text(
                                    "Upload Degree and Registration Certificate"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: fieldState.hasError
                                      ? Colors.redAccent
                                      : null,
                                ),
                              ),
                            ),
                            if (_degreePdf != null)
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                          ],
                        ),
                        if (fieldState.hasError)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "This document is required.",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Config.spaceMedium,
          ],

          TextFormField(
            controller: _passController,
            obscureText: obsecurePass,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => obsecurePass = !obsecurePass),
                icon: Icon(
                    obsecurePass ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password';
              }

              final password = value.trim();

              if (password.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!RegExp(r'[A-Z]').hasMatch(password)) {
                return 'Include at least one uppercase letter';
              }
              if (!RegExp(r'[a-z]').hasMatch(password)) {
                return 'Include at least one lowercase letter';
              }
              if (!RegExp(r'\d').hasMatch(password)) {
                return 'Include at least one number';
              }
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
                return 'Include at least one special character';
              }

              return null;
            },
          ),

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

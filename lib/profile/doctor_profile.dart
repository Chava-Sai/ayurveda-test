import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User? _user;
  Map<String, dynamic> _doctorData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    if (_user != null) {
      final doc = await _firestore.collection('doctors').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _doctorData = doc.data()!;
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateField(String fieldName, String title, String hint) async {
    TextEditingController controller =
        TextEditingController(text: _doctorData[fieldName]);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _firestore
                  .collection('doctors')
                  .doc(_user!.uid)
                  .update({fieldName: controller.text.trim()});
              setState(() {
                _doctorData[fieldName] = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    TextEditingController passwordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New Password'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _user!.updatePassword(passwordController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final cropped = await ImageCropper().cropImage(sourcePath: pickedFile.path);
    if (cropped == null) return;

    final ref = _storage.ref().child('profile_pics/${_user!.uid}.jpg');
    await ref.putFile(File(cropped.path));
    final downloadUrl = await ref.getDownloadURL();

    await _firestore
        .collection('doctors')
        .doc(_user!.uid)
        .update({"profileUrl": downloadUrl});
    setState(() => _doctorData['profileUrl'] = downloadUrl);
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Profile"),
        backgroundColor: Config.primaryColor,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05), // Dynamic padding
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: screenWidth *
                              0.17, // Dynamic size based on screen width
                          backgroundImage: _doctorData['profileUrl'] != null
                              ? NetworkImage(_doctorData['profileUrl'])
                              : const AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                        ),
                        IconButton(
                          onPressed: _pickAndUploadImage,
                          icon: const Icon(Icons.camera_alt, size: 22),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: const CircleBorder()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _doctorData['name'] ?? 'Doctor',
                    style: TextStyle(
                        fontSize: screenWidth * 0.06, // Dynamic font size
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: screenWidth * 0.055,
                          color: Colors.black), // Dynamic font size
                      children: [
                        const TextSpan(
                          text: 'Your ID: ',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: _doctorData['doctorId'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+91 ${_doctorData['phone'] ?? ''}',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.045), // Dynamic font size
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _buildSectionTitle("Settings"),
                  _buildTile(Icons.edit, "Change Name",
                      () => _updateField('name', 'Name', 'Enter your name')),
                  _buildTile(Icons.lock, "Change Password", _changePassword),
                  const Divider(),
                  _buildSectionTitle("Update Other Details"),
                  _buildTile(
                      Icons.school,
                      "Degree",
                      () => _updateField(
                          'degree', 'Degree', 'Enter your Degree')),
                  _buildTile(
                      Icons.medical_services,
                      "Specialization",
                      () => _updateField('specialization', 'Specialization',
                          'Enter Specialization')),
                  _buildTile(
                      Icons.work_history,
                      "Experience",
                      () => _updateField(
                          'experience', 'Experience', 'Enter Experience')),
                  _buildTile(
                      Icons.schedule,
                      "Slot Time",
                      () => _updateField(
                          'slotTime', 'Slot Time', 'Enter Slot Time')),
                  _buildTile(Icons.money, "Fee",
                      () => _updateField('fee', 'Fee', 'Enter Fee')),
                  _buildTile(
                      Icons.location_on,
                      "Location",
                      () => _updateField(
                          'location', 'Location', 'Enter Location')),
                  _buildTile(Icons.map, "State",
                      () => _updateField('state', 'State', 'Enter State')),
                  _buildTile(
                      Icons.info_outline,
                      "About",
                      () =>
                          _updateField('about', 'About', 'Describe Yourself')),
                  const Divider(),
                  _buildSectionTitle("Legal Policy"),
                  _buildTile(Icons.policy, "Privacy Policy", () {}),
                  _buildTile(Icons.description, "Terms & Conditions", () {}),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: screenWidth * 0.86,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.015), // Dynamic padding
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}

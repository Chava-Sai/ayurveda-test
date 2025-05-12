import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late User? _user;
  String _userName = "User";
  String _profileUrl = "";
  String _number = "Null";

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? "User";
          _profileUrl = userDoc['profileUrl'] ?? "";
          _number = userDoc['phone'] ?? "Null";
        });
      }
    }
  }

  Future<void> _changeName() async {
    TextEditingController nameController =
        TextEditingController(text: _userName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await _firestore
                    .collection('users')
                    .doc(_user!.uid)
                    .update({"name": newName});
                setState(() => _userName = newName);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
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
          decoration: const InputDecoration(labelText: "Enter new password"),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newPassword = passwordController.text.trim();
              if (newPassword.isNotEmpty) {
                await _user!.updatePassword(newPassword);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 70,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Config.primaryColor,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: 'Crop Image')
      ],
    );

    if (croppedFile == null) return;

    File imageFile = File(croppedFile.path);
    String fileName = "${_user!.uid}.jpg";
    Reference storageRef = _storage.ref().child("Customer/$fileName");

    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    await _firestore.collection('users').doc(_user!.uid).update({
      "profileUrl": downloadUrl,
    });

    setState(() => _profileUrl = downloadUrl);
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
        title: const Text("Profile"),
        backgroundColor: Config.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.17,
                          backgroundImage: _profileUrl.isNotEmpty
                              ? NetworkImage(_profileUrl)
                              : const AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                        ),
                        IconButton(
                          onPressed: _pickAndUploadImage,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Config.primaryColor,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+91 ${_number}',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: screenWidth * 0.045), // Dynamic font size
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              _buildSectionTitle("Settings"),
              _buildTile(Icons.edit, "Change Name", _changeName),
              _buildTile(Icons.lock, "Change Password", _changePassword),
              SizedBox(height: screenHeight * 0.03),
              _buildSectionTitle("Legal Policy"),
              _buildTile(Icons.policy, "Privacy Policy", () {}),
              _buildTile(Icons.description, "Terms & Conditions", () {}),
              SizedBox(height: screenHeight * 0.03),
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
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal[700]),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
          toolbarColor: Colors.blue,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo & Name
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
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
                            backgroundColor: Colors.blue,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.03,
                    ),
                    Center(
                      child: Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Settings Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Settings",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Change Name"),
                onTap: _changeName,
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Change Password"),
                onTap: _changePassword,
              ),

              const SizedBox(height: 20),

              // Legal Policy
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Legal Policy",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.policy),
                title: const Text("Privacy Policy"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text("Terms & Conditions"),
                onTap: () {},
              ),

              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.86,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

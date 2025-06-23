import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'home_screen.dart';

class ChatWrapper extends StatefulWidget {
  const ChatWrapper({super.key});

  @override
  State<ChatWrapper> createState() => _ChatWrapperState();
}

class _ChatWrapperState extends State<ChatWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // Check in users collection first
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        await _connectToChat(
            currentUser.uid, userDoc['name'], userDoc['profileUrl'] ?? '');
        return;
      }

      // If not found in users, check in doctors collection
      DocumentSnapshot doctorDoc =
          await _firestore.collection('doctors').doc(currentUser.uid).get();

      if (doctorDoc.exists) {
        await _connectToChat(
            currentUser.uid, doctorDoc['name'], doctorDoc['profileUrl'] ?? '');
        return;
      }

      // If user not found in either collection
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToChat(
      String userId, String userName, String userAvatar) async {
    try {
      await ZIMKit().connectUser(
        id: userId,
        name: userName,
        avatarUrl: userAvatar,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to initialize chat'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeChat,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class AutoDoctorCallScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const AutoDoctorCallScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<AutoDoctorCallScreen> createState() => _AutoDoctorCallScreenState();
}

class _AutoDoctorCallScreenState extends State<AutoDoctorCallScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;
  String? _callID;
  String? _userName;
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  @override
  void initState() {
    super.initState();
    _startCallAutomatically();
  }

  Future<void> _startCallAutomatically() async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // Fetch user name from Firestore 'users' collection
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Patient';

    // Generate unique call ID
    final callID =
        'call_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}';

    // Create a call document in Firestore
    final callDocRef =
        FirebaseFirestore.instance.collection('active_calls').doc(callID);

    await callDocRef.set({
      'caller_id': currentUser.uid,
      'doctor_id': widget.doctorId,
      'status': 'initiated',
      'created_at': FieldValue.serverTimestamp(),
    });

    // Listen for call status changes
    _callSubscription = callDocRef.snapshots().listen((snapshot) {
      if (!snapshot.exists || snapshot['status'] == 'ended') {
        if (mounted) Navigator.pop(context);
      }
    });

    setState(() {
      _callID = callID;
      _userName = userName;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = e.toString();
    });
  }
}

  @override
  void dispose() {
    _callSubscription?.cancel();
    // Mark call as ended when screen disposes
    if (_callID != null) {
      FirebaseFirestore.instance
          .collection('active_calls')
          .doc(_callID)
          .update({'status': 'ended'});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Starting Call...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startCallAutomatically,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
  child: ZegoUIKitPrebuiltCall(
      appID: 834408230,
      appSign: "d342fbf895ef4d7cae049320671b7489dca5be205ee94f5623e644744fa25df9",
      userID: _auth.currentUser?.uid ?? '',
      userName: _userName ?? 'Patient',
      callID: _callID!,
      config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
        ..topMenuBar.isVisible = true
        ..topMenuBar.buttons = [
          ZegoCallMenuBarButtonName.showMemberListButton,
          ZegoCallMenuBarButtonName.soundEffectButton,
        ]),
);
  }
}

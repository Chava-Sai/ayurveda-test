import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hosp_test/services/call_invite.dart';
import 'package:hosp_test/services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const CallScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isLoading = true;
  String _currentUserName = 'User';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  @override
  void dispose() {
    CallService.uninitialize();
    super.dispose();
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;

      // Check both users and doctors collections
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _currentUserName = userSnapshot['name'] ?? 'User';
        });
      } else {
        final doctorSnapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .get();

        if (doctorSnapshot.exists) {
          setState(() {
            _currentUserName = doctorSnapshot['name'] ?? 'Doctor';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initiateDoctorCall() async {
    try {
      // Initialize call service with current user's credentials
      await CallService.initializeCallService(
        userID: _currentUserId,
        userName: _currentUserName,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallInviteScreen(
            callerId: _currentUserId,
            callerName: _currentUserName,
            doctorId: widget.doctorId,
            doctorName: widget.doctorName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call initialization failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Doctor')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Calling: Dr. ${widget.doctorName}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_call, size: 28),
                    label: const Text('START VIDEO CALL',
                        style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _initiateDoctorCall,
                  ),
                ],
              ),
            ),
    );
  }
}

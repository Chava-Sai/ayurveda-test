import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

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
  bool _isCallInitialized = false;
  String _currentUserName = 'User';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  @override
  void dispose() {
    if (_isCallInitialized) {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
    }
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

      // Initialize call service
      await _initializeCallService();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeCallService() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: 834408230, // Your Zego app ID
        appSign:
            "d342fbf895ef4d7cae049320671b7489dca5be205ee94f5623e644744fa25df9", // Your Zego app sign
        userID: _currentUserId,
        userName: _currentUserName,
        plugins: [ZegoUIKitSignalingPlugin()],

        // For the latest versions, notification config is handled differently
        // onIncomingCallReceived: (context, invitationData) {
        //   // This will automatically show the incoming call UI
        //   return true; // Return true to accept the default handling
        // },

        // // For Android notifications
        // androidNotificationConfig: {
        //   'channelID': 'CallNotifications',
        //   'channelName': 'Call Notifications',
        //   'sound': 'call',
        //   'icon': 'notification_icon',
        // },

        // // For iOS notifications
        // iosNotificationConfig: {
        //   'systemCallingIconName': 'CallKitIcon',
        // },
      );

      setState(() => _isCallInitialized = true);
    } catch (e) {
      debugPrint('Error initializing call service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call service initialization failed: $e')),
        );
      }
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
                  if (!_isCallInitialized)
                    const Text('Initializing call service...')
                  else
                    ZegoSendCallInvitationButton(
                      isVideoCall: true,
                      resourceID: "zegouikit_call",
                      invitees: [
                        ZegoUIKitUser(
                            id: widget.doctorId, name: widget.doctorName)
                      ],
                      onPressed: (code, message, invitees) {
                        if (code.isNotEmpty) {
                          // Show error if call failed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Call failed: ${message.isNotEmpty ? message : 'Unknown error'}'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

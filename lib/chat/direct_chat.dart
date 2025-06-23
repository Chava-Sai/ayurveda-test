import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class AutoDoctorChatScreen extends StatefulWidget {
  final String doctorId;

  const AutoDoctorChatScreen({super.key, required this.doctorId});

  @override
  State<AutoDoctorChatScreen> createState() => _AutoDoctorChatScreenState();
}

class _AutoDoctorChatScreenState extends State<AutoDoctorChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _errorMessage;
  String? _doctorName;
  String? _doctorProfileUrl;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please login first.');
      }

      // 1. Get current user details (check both users and doctors collections)
      DocumentSnapshot? userDoc;
      String currentUserName = '';
      String currentUserAvatar = '';

      userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        currentUserName = userDoc['name'] ?? 'User';
        currentUserAvatar = userDoc['profileUrl'] ?? '';
      } else {
        userDoc =
            await _firestore.collection('doctors').doc(currentUser.uid).get();
        if (userDoc.exists) {
          currentUserName = userDoc['name'] ?? 'User';
          currentUserAvatar = userDoc['profileUrl'] ?? '';
        } else {
          throw Exception('User profile not found in database.');
        }
      }

      // 2. Get doctor details
      DocumentSnapshot doctorDoc =
          await _firestore.collection('doctors').doc(widget.doctorId).get();
      if (!doctorDoc.exists) {
        throw Exception('Doctor profile not found.');
      }

      setState(() {
        _doctorName = doctorDoc['name'] ?? 'Doctor';
        _doctorProfileUrl = doctorDoc['profileUrl'] ?? '';
      });

      // 3. Connect to ZIMKit with current user credentials
      await ZIMKit().connectUser(
        id: currentUser.uid,
        name: currentUserName,
        avatarUrl: currentUserAvatar,
      );

      // 4. Check if conversation already exists
      final existingConversation = await ZIMKit().getConversation(
        widget.doctorId,
        ZIMConversationType.peer,
      );

      // 5. Create new conversation if doesn't exist
      if (existingConversation == null) {
        final doc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .get();

        final uid = doc.data()?['uid'];

        if (uid != null && uid.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ZIMKitMessageListPage(
                conversationID: uid,
                conversationType: ZIMConversationType.peer,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Doctor UID not found.")),
          );
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Initializing Chat...')),
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
                onPressed: _initializeChat,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ZIMKitMessageListPage(
      conversationID: widget.doctorId,
      conversationType: ZIMConversationType.peer,
      // appBar: AppBar(
      //   title: Row(
      //     children: [
      //       if (_doctorProfileUrl != null && _doctorProfileUrl!.isNotEmpty)
      //         CircleAvatar(
      //           backgroundImage: NetworkImage(_doctorProfileUrl!),
      //           radius: 16,
      //         ),
      //       const SizedBox(width: 8),
      //       Text(_doctorName ?? 'Doctor'),
      //     ],
      //   ),
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      // ),
    );
  }
}

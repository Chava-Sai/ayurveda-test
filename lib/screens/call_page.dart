import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  const CallPage({Key? key, required this.callID}) : super(key: key);
  final String callID;

  Future<Map<String, String>> _fetchUserDataWithRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {"name": "User"};
      }

      // First check user in users collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return {
          "name": userData["name"] ?? "User",
        };
      }

      // If not found in users, check in doctors
      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doctorDoc.exists) {
        Map<String, dynamic> doctorData =
            doctorDoc.data() as Map<String, dynamic>;
        return {
          "name": doctorData["name"] ?? "Doctor",
        };
      }

      return {"name": "User"};
    } catch (e) {
      print("Error fetching user data: $e");
      return {"name": "User"};
    }
  }

  @override
  Widget build(BuildContext context) {
    final userID = FirebaseAuth.instance.currentUser?.uid ?? "unknown";

    return FutureBuilder<Map<String, String>>(
      future: _fetchUserDataWithRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userName = snapshot.data!['name'] ?? "User";

        return ZegoUIKitPrebuiltCall(
          appID: 346350858, // Your App ID
          appSign:
              "0b5a0cc7b9a48620f474ae57318840047a77acf0ddb6e5e82b144d871447fb07", // Your App Sign
          userID: userID,
          userName: userName,
          callID: callID,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

// class CallInviteScreen extends StatelessWidget {
//   final String callerId;
//   final String callerName;
//   final String doctorId;
//   final String doctorName;

//   const CallInviteScreen({
//     super.key,
//     required this.callerId,
//     required this.callerName,
//     required this.doctorId,
//     required this.doctorName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Connecting to Doctor'),
//         automaticallyImplyLeading: false,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             Text('Calling Dr. $doctorName...',
//                 style: const TextStyle(fontSize: 18)),
//             const SizedBox(height: 40),
//             ZegoSendCallInvitationButton(
//               isVideoCall: true,
//               resourceID: "zegouikit_call",
//               invitees: [ZegoUIKitUser(id: doctorId, name: doctorName)],
//               onPressed: (code, message, invitees) {
//                 Navigator.pop(context); // Return to previous screen

//                 if (code.isNotEmpty) {
//                   // Show error if call failed
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                           'Call failed: ${message.isNotEmpty ? message : 'Unknown error'}'),
//                       duration: const Duration(seconds: 3),
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

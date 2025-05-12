import 'package:flutter/material.dart';
import 'package:hosp_test/main_layout.dart';
import 'package:hosp_test/screens/auth_page.dart';
//import 'package:hosp_test/screens/booking_page.dart';
import 'package:hosp_test/screens/doctor_doctordetail.dart';
import 'package:hosp_test/screens/dotor_details.dart';
import 'package:hosp_test/screens/email_link.dart';
import 'package:hosp_test/screens/success_booked.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
//import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
//import 'package:zego_zimkit/zego_zimkit.dart';
import 'firebase_options.dart';
import 'package:hosp_test/doctor_main_layout.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  runApp(const SplashWrapper());
}

class SplashWrapper extends StatelessWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Kanvy Health Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(
          focusColor: Config.primaryColor,
          border: Config.outlinedBorder,
          focusedBorder: Config.focusBorder,
          errorBorder: Config.errorBorder,
          enabledBorder: Config.outlinedBorder,
          floatingLabelStyle: TextStyle(color: Config.primaryColor),
          prefixIconColor: Colors.black38,
        ),
        scaffoldBackgroundColor: Colors.white,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Config.primaryColor,
          selectedItemColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          unselectedItemColor: Colors.grey.shade700,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SplashScreenCheck(),
      routes: {
        'start': (context) => const AuthPage(),
        'main': (context) => const MainLayout(),
        'doc_details': (context) => const DoctorDetails(),
        'doc_docdetails': (context) => const doctorDoctorDetails(),
        'success_booking': (context) => const AppointmentBooked(),
        'email_sent': (context) => const EmailSent(),
        'login': (context) => const AuthPage(),
      },
    );
  }
}

class SplashScreenCheck extends StatefulWidget {
  const SplashScreenCheck({super.key});

  @override
  State<SplashScreenCheck> createState() => _SplashScreenCheckState();
}

class _SplashScreenCheckState extends State<SplashScreenCheck> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // splash wait

    final user = _auth.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        userDoc = await _firestore.collection('doctors').doc(user.uid).get();
      }

      if (userDoc.exists) {
        final lastLoginTimestamp = userDoc['lastLogin'] as Timestamp?;
        if (lastLoginTimestamp == null) {
          await _auth.signOut();
          Navigator.pushReplacementNamed(context, 'start');
          return;
        }

        final lastLogin = lastLoginTimestamp.toDate();
        final now = DateTime.now();
        final diff = now.difference(lastLogin).inDays;

        if (diff > 14) {
          await _auth.signOut();
          Navigator.pushReplacementNamed(context, 'start');
          return;
        }

        // ✅ Navigate to dashboard
        if (userDoc.reference.parent.id == 'doctors') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const doctorMainLayout()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MainLayout()));
        }
      } else {
        await _auth.signOut();
        Navigator.pushReplacementNamed(context, 'start');
      }
    } catch (e) {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, 'start');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

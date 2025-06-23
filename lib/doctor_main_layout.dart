import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hosp_test/chat/doctor_call_listener.dart';
import 'package:hosp_test/chat/login.dart';
import 'package:hosp_test/screens/appointment_page.dart';
import 'package:hosp_test/screens/doctor_home_page.dart';
import 'package:hosp_test/services/viewchat_page.dart';
import 'package:hosp_test/stores/store_page.dart'; // Make sure this is the correct path

class doctorMainLayout extends StatefulWidget {
  const doctorMainLayout({super.key});

  @override
  State<doctorMainLayout> createState() => _DoctorMainLayoutState();
}

class _DoctorMainLayoutState extends State<doctorMainLayout> {
  int currentPage = 0;
  final PageController _page = PageController();

  @override
  Widget build(BuildContext context) {
    return DoctorCallListener(
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(user.uid)
                        .update({'working': 'offline'});
                  }
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, 'login');
                },
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _page,
          onPageChanged: (value) {
            setState(() {
              currentPage = value;
            });
          },
          children: const <Widget>[
            doctorHomePage(),
            MedicineListWithFilterPage(),
            AppointmentPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentPage,
          onTap: (page) {
            setState(() {
              currentPage = page;
              _page.animateToPage(
                page,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.houseChimneyMedical),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded, size: 30),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.solidCalendarCheck),
              label: 'Appointments',
            ),
          ],
        ),
      ),
    );
  }
}

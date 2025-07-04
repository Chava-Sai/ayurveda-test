import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hosp_test/chat/login.dart';
import 'package:hosp_test/components/searchby_id.dart';
import 'package:hosp_test/screens/appointment_page.dart';
import 'package:hosp_test/screens/user_home_page.dart';
import 'package:hosp_test/services/viewchat_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int currentPage = 0;
  final PageController _page = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _page,
        onPageChanged: ((value) {
          setState(() {
            currentPage = value;
          });
        }),
        children: const <Widget>[
          UserHomePage(),
          SearchDoctorById(),
          ChatWrapper(), // Assuming this is the chat home page
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
              duration: const Duration(microseconds: 500),
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
            icon: Icon(
              Icons.search_rounded,
              size: 33,
            ),
            label: 'search',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.message_rounded,
              size: 30,
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.store_mall_directory_sharp,
              size: 30,
            ),
            label: 'Stores',
          ),
        ],
      ),
    );
  }
}

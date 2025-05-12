import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:hosp_test/components/appointment_card.dart';
import 'package:hosp_test/components/doctor_card.dart';
import 'package:hosp_test/profile/Appointment_page.dart';
import 'package:hosp_test/profile/doctor_profile.dart';
//import 'package:hosp_test/screens/appointment_page.dart';
import 'package:hosp_test/utils/config.dart';
//import 'package:hosp_test/profile/profile.dart';

class doctorHomePage extends StatefulWidget {
  const doctorHomePage({super.key});

  @override
  State<doctorHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<doctorHomePage> {
  late Future<List<Map<String, dynamic>>> _doctorFuture;
  late Future<Map<String, String>> _userDataFuture;
  String? _selectedLocation;
  String? _selectedLanguage;

  // List<Map<String, dynamic>> medCat = [
  //   {"icon": FontAwesomeIcons.userDoctor, "category": "General"},
  //   {"icon": FontAwesomeIcons.heartPulse, "category": "Cardiology"},
  //   {"icon": FontAwesomeIcons.lungs, "category": "Respirations"},
  //   {"icon": FontAwesomeIcons.hand, "category": "Dermatology"},
  //   {"icon": FontAwesomeIcons.personPregnant, "category": "Gynecology"},
  //   {"icon": FontAwesomeIcons.teeth, "category": "Dental"},
  // ];

  @override
  void initState() {
    super.initState();
    _doctorFuture = fetchDoctors();
    _userDataFuture = _fetchUserData(); // ✅ Fetch user data
  }

  /// 🔍 Fetches **Doctors** from `users` collection
  Future<List<Map<String, dynamic>>> fetchDoctors() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('role', isEqualTo: 'Doctor')
          .where('status', isEqualTo: 'approved')
          // .where('emailVerified', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "name": data["name"] ?? "Unknown",
          "specialization": data["specialization"] ?? "Not Specified",
          "address": data["clinicAddress"] ?? "Not Available",
          "degree": data["degree"] ?? "Not Available",
          "about": data["about"] ?? "Not Available",
          "fee": data["fee"] ?? "Not Available",
          'slotTime': data["slotTime"] ?? "Not Available",
          "experience": data["experience"] ?? "N/A",
          "state": data["state"] ?? "Not Specified",
          "registrationNumber": data["registrationNumber"] ?? "N/A",
          "profileUrl": data["profileUrl"]?.toString() ?? "",
          "location": data["location"] ?? "Not specified",
          "language": List<String>.from(data["language"] ?? []),
        };
      }).toList();
    } catch (e) {
      print("Error fetching doctors: $e");
      return [];
    }
  }

  /// 🔍 Fetches **Logged-in User's Name & Profile Image**
  Future<Map<String, String>> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {"name": "User", "profileUrl": ""};
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      // Ensure `data()` is not null before accessing fields
      if (!userDoc.exists || userDoc.data() == null) {
        return {"name": "User", "profileUrl": ""};
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      return {
        "name": userData["name"] ?? "User",
        "profileUrl": userData["profileUrl"]?.toString() ??
            "", // Convert to string safely
      };
    } catch (e) {
      print("Error fetching user data: $e");
      return {"name": "User", "profileUrl": ""};
    }
  }

  /// 🔄 Refreshes doctors list when swiping down
  Future<void> _refreshData() async {
    setState(() {
      _doctorFuture = fetchDoctors();
      _userDataFuture = _fetchUserData(); // ✅ Refresh user data too
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
 //   final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu,
                                size: 28), // 3-line menu icon
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (BuildContext context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading:
                                            const Icon(Icons.calendar_today),
                                        title: const Text("Appointments"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    AppointmentTodayPage()),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.person),
                                        title: const Text("Profile"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DoctorProfilePage()),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.logout,
                                            color: Colors.red),
                                        title: const Text("Logout",
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onTap: () {
                                          FirebaseAuth.instance.signOut();
                                          Navigator.pop(context);
                                          Navigator.pushReplacementNamed(
                                              context, 'login');
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(
                            width: screenWidth * 0.001,
                          ), // Space between menu icon and name
                          FutureBuilder<Map<String, String>>(
                            future: _userDataFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  "Loading...",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                );
                              }
                              return Text(
                                "Dr.${snapshot.data?["name"] ?? "User"}!",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      FutureBuilder<Map<String, String>>(
                        future: _userDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircleAvatar(
                              radius: 25,
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            );
                          }

                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!["profileUrl"] == "") {
                            return const CircleAvatar(
                              radius: 25,
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            );
                          }

                          return CircleAvatar(
                            radius: screenWidth * 0.07,
                            backgroundImage:
                                NetworkImage(snapshot.data!["profileUrl"]!),
                          );
                        },
                      ),
                    ],
                  ),
                  //Config.spaceMedium,
                  // const Text(
                  //   'Category',
                  //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  // ),
                  // Config.spaceSmall,
                  // SizedBox(
                  //   height: 40.0,
                  //   child: ListView(
                  //     scrollDirection: Axis.horizontal,
                  //     children: medCat.map((category) {
                  //       return Card(
                  //         margin: const EdgeInsets.only(right: 20),
                  //         color: Config.primaryColor,
                  //         child: Padding(
                  //           padding: const EdgeInsets.symmetric(
                  //               horizontal: 15, vertical: 10),
                  //           child: Row(
                  //             children: <Widget>[
                  //               FaIcon(category['icon'], color: Colors.white),
                  //               const SizedBox(width: 20),
                  //               Text(
                  //                 category['category'],
                  //                 style: const TextStyle(
                  //                     fontSize: 16,
                  //                     fontWeight: FontWeight.bold,
                  //                     color: Colors.white),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       );
                  //     }).toList(),
                  //   ),
                  // ),
                  Config.spaceSmall,
                  const Text(
                    'Doctors Available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Config.spaceSmall,
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _doctorFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Text(
                                _selectedLocation != null ||
                                        _selectedLanguage != null
                                    ? "No doctors found matching your criteria."
                                    : "No approved doctors found.",
                              ),
                              TextButton(
                                onPressed: _refreshData,
                                child: const Text("Refresh"),
                              ),
                            ],
                          ),
                        );
                      }

                      final now = TimeOfDay.now();
                      final currentMinutes = now.hour * 60 + now.minute;

                      List<Map<String, dynamic>> filteredDoctors =
                          snapshot.data!.where((doctor) {
                        String slotTime = doctor["slotTime"] ?? "";
                        final parts = slotTime.toLowerCase().split("to");

                        if (parts.length != 2) return false;

                        TimeOfDay? parseTime(String input) {
                          try {
                            final isPM = input.contains('pm');
                            final clean =
                                input.replaceAll(RegExp(r'[^\d:]'), '');
                            final parts = clean.split(':');

                            int hour = int.parse(parts[0]);
                            int minute =
                                parts.length > 1 ? int.parse(parts[1]) : 0;

                            if (isPM && hour < 12) hour += 12;
                            if (!isPM && hour == 12) hour = 0;

                            return TimeOfDay(hour: hour, minute: minute);
                          } catch (e) {
                            return null;
                          }
                        }

                        final startTime = parseTime(parts[0].trim());
                        final endTime = parseTime(parts[1].trim());

                        if (startTime == null || endTime == null) return false;

                        final startMinutes =
                            startTime.hour * 60 + startTime.minute;
                        final endMinutes = endTime.hour * 60 + endTime.minute;

                        return currentMinutes >= startMinutes &&
                            currentMinutes <= endMinutes;
                      }).toList();

                      if (filteredDoctors.isEmpty) {
                        return Center(
                          child: Text("No doctors are available at this time."),
                        );
                      }

                      return Column(
                        children: filteredDoctors.map((doctor) {
                          return DoctorCard(
                            doctorId: doctor["id"],
                            name: doctor["name"],
                            fee: doctor["fee"] ?? "N/A",
                            experience: doctor["experience"] ?? "N/A",
                            slotTime: doctor["slotTime"] ?? "N/A",
                            degree: doctor["degree"] ?? "N/A",
                            specialization: doctor["specialization"],
                            address: doctor["address"],
                            about: doctor["about"],
                            state: doctor["state"],
                            registrationNumber: doctor["registrationNumber"],
                            profileUrl: doctor["profileUrl"],
                            location: doctor["location"],
                            route: 'doc_docdetails',
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hosp_test/components/appointment_card.dart';
import 'package:hosp_test/components/doctor_card.dart';
import 'package:hosp_test/profile/profile.dart';
import 'package:hosp_test/utils/config.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<UserHomePage> {
  late Future<List<Map<String, dynamic>>> _doctorFuture;
  late Future<Map<String, String>> _userDataFuture;

  List<Map<String, dynamic>> medCat = [
    {"icon": FontAwesomeIcons.userDoctor, "category": "General"},
    {"icon": FontAwesomeIcons.heartPulse, "category": "Cardiology"},
    {"icon": FontAwesomeIcons.lungs, "category": "Respirations"},
    {"icon": FontAwesomeIcons.hand, "category": "Dermatology"},
    {"icon": FontAwesomeIcons.personPregnant, "category": "Gynecology"},
    {"icon": FontAwesomeIcons.teeth, "category": "Dental"},
  ];

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
          .where('emailVerified', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "name": data["name"] ?? "Unknown",
          "specialization": data["specialization"] ?? "Not Specified",
          "address": data["clinicAddress"] ?? "Not Available",
          "registrationNumber": data["registrationNumber"] ?? "N/A",
          "profileUrl":
              data.containsKey("profileUrl") && data["profileUrl"] != null
                  ? data["profileUrl"] as String
                  : "", // ✅ Ensure profileUrl is always a String
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
          .collection('users')
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
                                          Navigator.pushNamed(context, 'login');
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
                                                    ProfilePage()),
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
                          const SizedBox(
                              width: 10), // Space between menu icon and name
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
                                "Hi ${snapshot.data?["name"] ?? "User"}!",
                                style: const TextStyle(
                                  fontSize: 24,
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
                            radius: 30,
                            backgroundImage:
                                NetworkImage(snapshot.data!["profileUrl"]!),
                          );
                        },
                      ),
                    ],
                  ),
                  Config.spaceMedium,
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Config.spaceSmall,
                  SizedBox(
                    height: 40.0,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: medCat.map((category) {
                        return Card(
                          margin: const EdgeInsets.only(right: 20),
                          color: Config.primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: Row(
                              children: <Widget>[
                                FaIcon(category['icon'], color: Colors.white),
                                const SizedBox(width: 20),
                                Text(
                                  category['category'],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Config.spaceSmall,
                  const Text(
                    'Appointment Today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Config.spaceSmall,
                  const AppointmentCard(),
                  Config.spaceSmall,
                  const Text(
                    'Our Doctors',
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
                        return const Center(
                            child: Text("No approved doctors found."));
                      }
                      return Column(
                        children: snapshot.data!.map((doctor) {
                          return DoctorCard(
                            doctorId: doctor["id"],
                            name: doctor["name"],
                            specialization: doctor["specialization"],
                            address: doctor["address"],
                            registrationNumber: doctor["registrationNumber"],
                            profileUrl: doctor["profileUrl"], // ✅ Now safe
                            route: 'doc_details',
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

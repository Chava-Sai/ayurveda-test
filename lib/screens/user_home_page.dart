import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hosp_test/components/doctor_card.dart';
import 'package:hosp_test/profile/Appointment_page.dart';
import 'package:hosp_test/profile/profile.dart';
import 'package:hosp_test/screens/appointment_page.dart';
import 'package:hosp_test/utils/config.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<UserHomePage> {
  late Future<List<Map<String, dynamic>>> _doctorFuture;
  late Future<Map<String, String>> _userDataFuture;

  // Filter state variables
  String? _selectedLocation;
  String? _selectedLanguage;
  final List<String> _locations = ['Vijayawada', 'Hyderabad', 'Bangalore'];
  final List<String> _language = ['Telugu', 'English', 'Hindi'];

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
    _userDataFuture = _fetchUserData();
  }

  /// Fetches doctors with optional filters
  Future<List<Map<String, dynamic>>> fetchDoctors({
    String? location,
    String? language,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('doctors')
          .where('status', isEqualTo: 'approved');

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (language != null && language.isNotEmpty) {
        query = query.where('language', arrayContains: language);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "name": data["name"] ?? "Unknown",
          "specialization": data["specialization"] ?? "Not Specified",
          "address": data["clinicAddress"] ?? "Not Available",
          "degree": data["degree"] ?? "Not Available",
          "about": data["about"] ?? "Not Available",
          "experience": data["experience"] ?? "Not Available",
          "state": data["state"] ?? "Not Specified",
          "fee": data["fee"] ?? "Not Specified",
          "slotTime": data["slotTime"] ?? "Not Specified",
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

  /// Fetches logged-in user's data
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

      if (!userDoc.exists || userDoc.data() == null) {
        return {"name": "User", "profileUrl": ""};
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      return {
        "name": userData["name"] ?? "User",
        "profileUrl": userData["profileUrl"]?.toString() ?? "",
      };
    } catch (e) {
      print("Error fetching user data: $e");
      return {"name": "User", "profileUrl": ""};
    }
  }

  /// Refreshes data
  Future<void> _refreshData() async {
    setState(() {
      _doctorFuture = fetchDoctors(
        location: _selectedLocation,
        language: _selectedLanguage,
      );
      _userDataFuture = _fetchUserData();
    });
  }

  /// Searches doctors with selected filters
  void _searchDoctors() {
    setState(() {
      _doctorFuture = fetchDoctors(
        location: _selectedLocation,
        language: _selectedLanguage,
      );
    });
  }

  /// Clears all filters
  void _clearFilters() {
    setState(() {
      _selectedLocation = null;
      _selectedLanguage = null;
      _doctorFuture = fetchDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                  // Header with menu and profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, size: 30),
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
                          SizedBox(
                            width: screenWidth * 0.01,
                          ),
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
                              return SizedBox(
                                width: screenWidth *
                                    0.45, // Limit width explicitly
                                child: Text(
                                  "Hi ${snapshot.data?["name"] ?? "User"}!",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.065,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        width: screenWidth * 0.09,
                      ),
                      FutureBuilder<Map<String, String>>(
                        future: _userDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircleAvatar(
                              radius: screenWidth * 0.07,
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            );
                          }

                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!["profileUrl"] == "") {
                            return CircleAvatar(
                              radius: screenWidth * 0.07,
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            );
                          }

                          return CircleAvatar(
                            radius: screenWidth *
                                0.09, // approximately 25 on a 360dp width screen
                            backgroundImage:
                                NetworkImage(snapshot.data!["profileUrl"]!),
                          );
                        },
                      ),
                    ],
                  ),
                  // Config.spaceMedium,

                  // Categories
                  // const Text(
                  //   'Category',
                  //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  // ),
                  // Config.spaceSmall,
                  // SizedBox(
                  //   height: 40.0,
                  //   child: ListView(
                  //     scrollDirection: Axis.horizontal,
                  //     children:
                  //   ),
                  // ),
                  Config.spaceSmall,

                  // Filter Section
                  const Text(
                    'Find Doctors By',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Config.spaceSmall,

                  // Location Dropdown
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    hint: const Text('All Locations'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ..._locations.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedLocation = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Config.spaceSmall,

                  // Language Dropdown (Single Selection)
                  const Text(
                    'Language',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    hint: const Text('All language'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All language'),
                      ),
                      ..._language.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Config.spaceSmall,

                  // Filter Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _clearFilters,
                          child: const Text(
                            'Clear Filters',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Config.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _searchDoctors,
                          child: const Text(
                            'Search Doctors',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Config.spaceMedium,

                  // Doctors List
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hosp_test/screens/dotor_details.dart';

class SearchDoctorById extends StatefulWidget {
  const SearchDoctorById({super.key});

  @override
  State<SearchDoctorById> createState() => _SearchDoctorByIdState();
}

class _SearchDoctorByIdState extends State<SearchDoctorById> {
  final TextEditingController _idController = TextEditingController();
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _doctorData;

  Future<void> _handleRefresh() async {
    setState(() {
      _idController.clear();
      _error = null;
      _doctorData = null;
      _loading = false;
    });
  }

  Future<void> _searchDoctor() async {
    FocusScope.of(context).unfocus(); // 👈 Hides the keyboard

    final doctorId = _idController.text.trim().toUpperCase();
    if (doctorId.isEmpty) {
      setState(() {
        _error = "Please enter a Doctor ID";
        _doctorData = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _doctorData = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('doctors')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _error = "No doctor found with ID $doctorId";
        });
      } else {
        setState(() {
          _doctorData = query.docs.first.data();
          _doctorData!['documentId'] = query.docs.first.id;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Something went wrong: ${e.toString()}";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Search Doctor by ID',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  const Text(
                    "Enter Doctor Unique ID (e.g., KH01)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      hintText: "Doctor ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _searchDoctor,
                      icon: const Icon(Icons.search, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3.0),
                        child: Text(
                          "Search Doctor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        shadowColor: Colors.black54,
                      ),
                    ),
                  ),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_doctorData != null) _buildDoctorCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context) {
    final data = _doctorData!;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetails(),
            settings: RouteSettings(
              arguments: {
                'doctorId': data['documentId'],
                'name': data['name'],
                'degree': data['degree'],
                'specialization': data['specialization'],
                'experience': data['experience'],
                'userId': data['uid'],
                'slotTime': data['slotTime'],
                'about': data['about'],
                'state': data['state'],
                'fee': data['fee'],
                'location': data['location'],
                'profileUrl': data['profileUrl'],
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(top: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.15,
                backgroundImage: data['profileUrl'] != null
                    ? NetworkImage(data['profileUrl'])
                    : const AssetImage('assets/doctor1.jpeg') as ImageProvider,
              ),
              const SizedBox(height: 15),
              Text(
                "Dr. ${data['name']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${data['specialization']} - ${data['degree']}",
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    "${data['location']}, ${data['state']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const Divider(height: 25, thickness: 1.2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile(
                      "Experience", "${data['experience']} yrs", Icons.school),
                  _infoTile("Fee", "₹${data['fee']}", Icons.currency_rupee),
                  //_infoTile("Slot", data['slotTime'], Icons.schedule),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetails(),
                      settings: RouteSettings(arguments: {
                        'doctorId': data['documentId'],
                        'name': data['name'],
                        'degree': data['degree'],
                        'specialization': data['specialization'],
                        'experience': data['experience'],
                        'userId': data['uid'],
                        'slotTime': data['slotTime'],
                        'about': data['about'],
                        'state': data['state'],
                        'fee': data['fee'],
                        'location': data['location'],
                        'profileUrl': data['profileUrl'],
                      }),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text("View Full Details"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black)),
      ],
    );
  }
}

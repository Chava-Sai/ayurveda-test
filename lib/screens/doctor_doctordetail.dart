import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hosp_test/chat/direct_chat.dart';
import 'package:hosp_test/chat/home_screen.dart';
import 'package:hosp_test/chat/login.dart';
import 'package:hosp_test/components/button.dart';
//import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/components/custom_appbar.dart';
import 'package:hosp_test/screens/call_page.dart';
import 'package:hosp_test/screens/doctor_status_button.dart';
import 'package:hosp_test/services/final_call.dart';
//import 'package:hosp_test/screens/call_page.dart';
import 'package:hosp_test/utils/config.dart';

class doctorDoctorDetails extends StatefulWidget {
  const doctorDoctorDetails({super.key});

  @override
  State<doctorDoctorDetails> createState() => _doctorDoctorDetailsState();
}

class _doctorDoctorDetailsState extends State<doctorDoctorDetails> {
  bool isFav = false;
  bool isSlotActive = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String name;
  late String experience;
  late String degree;
  late String about;
  late String location;
  late String userId;
  late String fee;
  late String doctorId;
  late String slotTime;
  late String state;
  late String doctorStatus;
  late String specialization;
  late String profileUrl;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    name = args['name']?.toString() ?? '';
    degree = args['degree']?.toString() ?? '';
    specialization = args['specialization']?.toString() ?? '';
    experience = args['experience']?.toString() ?? '';
    userId = args['userId']?.toString() ?? '';
    slotTime = args['slotTime']?.toString() ?? '';
    about = args['about']?.toString() ?? '';
    state = args['state']?.toString() ?? '';
    doctorId = args['doctorId']?.toString() ?? '';
    fee = args['fee']?.toString() ?? '';
    doctorStatus = args['working']?.toString() ?? 'available';
    location = args['location']?.toString() ?? '';
    profileUrl = args['profileUrl']?.toString() ?? '';

    isSlotActive = isCurrentTimeWithinSlot(slotTime);
  }

  Future<void> _loadDoctorStatus() async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        setState(() {
          doctorStatus = doc['working'] ?? 'available';
          _isLoading = false;
        });
      } else {
        _isLoading = false;
      }
    } catch (e) {
      debugPrint('Error loading doctor status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isSlotActive = isCurrentTimeWithinSlot(slotTime);
      _loadDoctorStatus();
    });
  }

  bool isCurrentTimeWithinSlot(String slotTime) {
    final now = TimeOfDay.now();
    final parts = slotTime.toLowerCase().split('to');
    if (parts.length != 2) return false;

    TimeOfDay parseTime(String timeStr) {
      final isPM = timeStr.contains('pm');
      final clean = timeStr.replaceAll(RegExp(r'[^\d:]'), '');
      final split = clean.split(':');

      int hour = int.parse(split[0]);
      int minute = split.length > 1 ? int.parse(split[1]) : 0;

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    final start = parseTime(parts[0].trim());
    final end = parseTime(parts[1].trim());

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  String formatSlotTime(String slotTime) {
    final parts = slotTime.toLowerCase().split('to');
    if (parts.length != 2) return slotTime;

    String extractHourMinute(String time) {
      final trimmed = time.trim().split(' ')[0];
      return trimmed;
    }

    String getMeridiem(String time) {
      return time.toLowerCase().contains('pm') ? 'PM' : 'AM';
    }

    final start = extractHourMinute(parts[0]);
    final end = extractHourMinute(parts[1]);
    final meridiem = getMeridiem(parts[1]);

    return "$start to $end $meridiem";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('doctors').doc(doctorId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final docData = snapshot.data!.data() as Map<String, dynamic>;
        doctorStatus = docData['working'] ?? 'available';

        return Scaffold(
          appBar: CustomAppBar(
            appTitle: 'Doctor Details',
            icon: const FaIcon(Icons.arrow_back_ios),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                    right: 8.0), // or EdgeInsets.symmetric(horizontal: 8)
                child: DoctorStatusButton(doctorId: doctorId),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  AboutDoctor(
                    name: name,
                    experience: experience,
                    degree: degree,
                    profileUrl: profileUrl,
                    location: location,
                    doctorId: doctorId,
                    userId: userId,
                    state: state,
                    specialization: specialization,
                    screenWidth: screenWidth,
                  ),
                  DetailBody(
                    experience: experience,
                    about: about,
                    fee: fee,
                    slotTime: formatSlotTime(slotTime),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05),
                        child: Row(
                          children: [
                            // Chat Button
                            Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsets.only(right: screenWidth * 0.02),
                                child: Button(
                                  width: double.infinity,
                                  title: 'Chat',
                                  onPressed: (isSlotActive &&
                                          doctorStatus == 'available')
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AutoDoctorChatScreen(
                                                      doctorId: doctorId),
                                            ),
                                          );
                                        }
                                      : null,
                                  disable: !(isSlotActive &&
                                      doctorStatus == 'available'),
                                ),
                              ),
                            ),
                            // Video Call Button
                            Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: screenWidth * 0.02),
                                child: Button(
                                  width: double.infinity,
                                  title: 'Video Call',
                                  onPressed: (isSlotActive &&
                                          doctorStatus == 'available')
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CallScreen(
                                                  doctorId: doctorId,
                                                  doctorName: name),
                                            ),
                                          );
                                        }
                                      : null,
                                  disable: !(isSlotActive &&
                                      doctorStatus == 'available'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Message
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Builder(
                          builder: (context) {
                            if (!isSlotActive) {
                              return Text(
                                "Chat and Video Call are allowed only during the available slot time.",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: screenWidth * 0.03),
                                textAlign: TextAlign.center,
                              );
                            } else if (doctorStatus == 'offline') {
                              return Text(
                                "Doctor is currently offline. Please try again later.",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: screenWidth * 0.03),
                                textAlign: TextAlign.center,
                              );
                            } else if (doctorStatus == 'busy') {
                              return Text(
                                "Doctor is currently busy. Please try again later.",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: screenWidth * 0.03),
                                textAlign: TextAlign.center,
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AboutDoctor extends StatelessWidget {
  final String name;
  final String profileUrl;
  final String degree;
  final String state;
  final String experience;
  final String userId;
  final String doctorId;
  final String location;
  final String specialization;
  final double screenWidth;

  const AboutDoctor({
    super.key,
    required this.name,
    required this.degree,
    required this.location,
    required this.state,
    required this.doctorId,
    required this.userId,
    required this.experience,
    required this.specialization,
    required this.profileUrl,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: screenWidth * 0.19,
          backgroundImage: NetworkImage(profileUrl),
          backgroundColor: Colors.white,
        ),
        SizedBox(height: screenWidth * 0.09),
        Text(
          'Dr. $name',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenWidth * 0.06),
        Text(
          "$specialization, $degree",
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: screenWidth * 0.06),
        Text(
          "$location, $state",
          style: TextStyle(
            fontSize: screenWidth * 0.043,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DetailBody extends StatelessWidget {
  final String experience;
  final String about;
  final String fee;
  final String slotTime;
  final double screenWidth;
  final double screenHeight;

  const DetailBody({
    super.key,
    required this.experience,
    required this.about,
    required this.slotTime,
    required this.fee,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: screenHeight * 0.02),
          DoctorInfo(
            experience: experience,
            fee: fee,
            slotTime: slotTime,
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            'About Doctor',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            about,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorInfo extends StatelessWidget {
  final String experience;
  final String fee;
  final String slotTime;
  final double screenWidth;

  const DoctorInfo({
    super.key,
    required this.experience,
    required this.slotTime,
    required this.fee,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        InfoCard(
            label: 'Experience\n(In Years)',
            value: "$experience years",
            width: screenWidth),
        SizedBox(width: screenWidth * 0.03),
        InfoCard(label: 'Slot Time', value: slotTime, width: screenWidth),
        SizedBox(width: screenWidth * 0.03),
        InfoCard(
            label: 'Fee\n(Per Visit)', value: "Rs.$fee", width: screenWidth),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard(
      {super.key,
      required this.label,
      required this.value,
      required this.width});

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Config.primaryColor,
        ),
        padding: EdgeInsets.symmetric(
          vertical: width * 0.07,
          horizontal: width * 0.035,
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.033,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.035,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

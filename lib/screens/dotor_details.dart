import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/components/custom_appbar.dart';
import 'package:hosp_test/screens/call_page.dart';
import 'package:hosp_test/utils/config.dart';

class DoctorDetails extends StatefulWidget {
  const DoctorDetails({super.key});

  @override
  State<DoctorDetails> createState() => _DoctorDetailsState();
}

class _DoctorDetailsState extends State<DoctorDetails> {
  bool isFav = false;
  bool isSlotActive = false;

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
  late String specialization;
  late String profileUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    name = args['name']!;
    degree = args['degree']!;
    specialization = args['specialization']!;
    experience = args['experience']!;
    userId = args['userId']!;
    slotTime = args['slotTime']!;
    about = args['about']!;
    state = args['state']!;
    doctorId = args['doctorId']!;
    fee = args['fee']!;
    location = args['location']!;
    profileUrl = args['profileUrl']!;

    isSlotActive = isCurrentTimeWithinSlot(slotTime);
  }

  Future<void> _refreshData() async {
    setState(() {
      isSlotActive = isCurrentTimeWithinSlot(slotTime);
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
      final trimmed = time.trim().split(' ')[0]; // Get "5:30" from "5:30 PM"
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
    return Scaffold(
      appBar: CustomAppBar(
        appTitle: 'Doctor Details',
        icon: const FaIcon(Icons.arrow_back_ios),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isFav = !isFav;
              });
            },
            icon: FaIcon(
              isFav ? Icons.favorite_rounded : Icons.favorite_outline,
              color: Colors.red,
            ),
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
              ),
              DetailBody(
                experience: experience,
                about: about,
                fee: fee,
                slotTime: formatSlotTime(slotTime),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1, left: 20, right: 20),
                child: Button(
                  width: double.infinity,
                  title: 'Book Appointment',
                  onPressed: isSlotActive
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CallPage(
                                callID: doctorId,
                              ),
                            ),
                          );
                        }
                      : null,
                  disable: !isSlotActive,
                ),
              ),
              if (!isSlotActive)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Booking is allowed only during the available slot time.",
                    style: TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 65.0,
            backgroundImage: NetworkImage(profileUrl),
            backgroundColor: Colors.white,
          ),
          Config.spaceMedium,
          Text(
            'Dr. $name',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Config.spaceSmall,
          Text(
            "$specialization,  $degree",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
          Config.spaceSmall,
          Text(
            "$location, $state",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DetailBody extends StatelessWidget {
  final String experience;
  final String about;
  final String fee;
  final String slotTime;

  const DetailBody({
    super.key,
    required this.experience,
    required this.about,
    required this.slotTime,
    required this.fee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          DoctorInfo(
            experience: experience,
            fee: fee,
            slotTime: slotTime,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          const Text(
            'About Doctor',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Text(
            about,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            softWrap: true,
            textAlign: TextAlign.justify,
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

  const DoctorInfo({
    super.key,
    required this.experience,
    required this.slotTime,
    required this.fee,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 15),
        InfoCard(label: 'Experience\n(In Years)', value: "$experience years"),
        SizedBox(width: 15),
        InfoCard(label: 'Slot Time', value: slotTime),
        SizedBox(width: 15),
        InfoCard(label: 'Fee\n(Per Visit)', value: "Rs.$fee"),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Config.primaryColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

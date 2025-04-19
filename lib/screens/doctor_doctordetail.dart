import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hosp_test/components/button.dart';
import 'package:hosp_test/components/custom_appbar.dart';
import 'package:hosp_test/screens/call_page.dart';
import 'package:hosp_test/utils/config.dart';

class doctorDoctorDetails extends StatefulWidget {
  const doctorDoctorDetails({super.key});

  @override
  State<doctorDoctorDetails> createState() => _doctorDoctorDetailsState();
}

class _doctorDoctorDetailsState extends State<doctorDoctorDetails> {
  bool isFav = false;

  late String name;
  late String experience;
  late String degree;
  late String about;
  late String location;
  late String fee;
  late String slotTime;
  late String doctorId;
  late String state;
  late String specialization;
  late String profileUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract arguments passed from DoctorCard
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    name = args['name']!;
    degree = args['degree']!;
    specialization = args['specialization']!;
    experience = args['experience']!;
    about = args['about']!;
    slotTime = args['slotTime']!;
    state = args['state']!;
    doctorId = args['doctorId']!;
    fee = args['fee']!;
    location = args['location']!;
    profileUrl = args['profileUrl']!;
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
        child: ListView(
          children: <Widget>[
            AboutDoctor(
              name: name,
              experience: experience,
              degree: degree,
              profileUrl: profileUrl,
              location: location,
              doctorId: doctorId,
              state: state,
              specialization: specialization,
            ),
            DetailBody(
              experience: experience,
              about: about,
              fee: fee,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1, left: 20, right: 20),
              child: Button(
                width: double.infinity,
                title: 'Book Appointment',
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CallScreen(
                                doctorId: doctorId,
                                doctorName: name,
                              )));
                },
                disable: false,
              ),
            ),
          ],
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
  final String doctorId;
  final String experience;
  final String location; // Default value
  final String specialization; // Default value

  const AboutDoctor(
      {super.key,
      required this.name,
      required this.degree,
      required this.location,
      required this.state,
      required this.experience,
      required this.doctorId,
      required this.specialization,
      required this.profileUrl});

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
                fontWeight: FontWeight.bold),
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
          // Config.spaceSmall,
        ],
      ),
    );
  }
}

class DetailBody extends StatelessWidget {
  final String experience;
  final String about;
  final String fee;

  const DetailBody(
      {super.key,
      required this.experience,
      required this.about,
      required this.fee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          DoctorInfo(
            experience: experience,
            fee: fee, // Pass the experience here
          ), // Pass the experience here
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.03,
          ),
          const Text(
            'About Doctor',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          Text(
            about, // Display the passed experience here
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

  const DoctorInfo({
    super.key,
    required this.experience,
    required this.fee,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // InfoCard(
        //   label: 'Patients',
        //   value: '109',
        // ),
        SizedBox(
          width: 15,
        ),
        InfoCard(
          label: 'Experience',
          value: "$experience years",
        ),
        SizedBox(
          width: 15,
        ),
        InfoCard(
          label: 'Fee',
          value: "Rs.$fee",
        ),
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
        padding: const EdgeInsets.symmetric(
          vertical: 30,
          horizontal: 15,
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

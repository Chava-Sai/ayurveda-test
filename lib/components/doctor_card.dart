import 'package:flutter/material.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    Key? key,
    required this.doctorId,
    required this.name,
    required this.degree,
    required this.specialization,
    required this.address,
    required this.registrationNumber,
    required this.profileUrl,
    required this.location,
    required this.route,
  }) : super(key: key);

  final String doctorId;
  final String name;
  final String degree;
  final String specialization;
  final String location;
  final String address;
  final String registrationNumber;
  final String profileUrl;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      height: 150,
      child: GestureDetector(
        child: Card(
          elevation: 5,
          color: Colors.white,
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.height * 0.15,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: profileUrl.isNotEmpty
                      ? Image.network(
                          profileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/doctor1.jpeg');
                          },
                        )
                      : Image.asset('assets/doctor1.jpeg'),
                ),
              ),
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Dr. $name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        specialization,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            degree,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.16,
                          ),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          final args = {
            'doctorId': doctorId,
            'name': name,
            'specialization': specialization,
            'degree': degree,
            'experience': '25 years',
            'profileUrl': profileUrl,
          };
          print("Navigating with arguments: $args"); // Debugging print
          Navigator.of(context).pushNamed(route, arguments: args);
        },
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    Key? key,
    required this.doctorId,
    required this.name,
    required this.degree,
    required this.specialization,
    required this.address,
    required this.state,
    required this.experience,
    required this.slotTime,
    required this.fee,
    required this.registrationNumber,
    required this.profileUrl,
    required this.location,
    required this.about,
    required this.route,
  }) : super(key: key);

  final String doctorId;
  final String name;
  final String degree;
  final String specialization;
  final String location;
  final String about;
  final String experience;
  final String slotTime;
  final String fee;
  final String address;
  final String state;
  final String registrationNumber;
  final String profileUrl;
  final String route;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double imageSize = screenHeight * 0.13;
    final double cardHeight = screenHeight * 0.18;
    final double horizontalPadding = screenWidth * 0.03;
    final double verticalPadding = screenHeight * 0.015;

    final String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? "unknown";

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      height: cardHeight,
      child: GestureDetector(
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                margin: EdgeInsets.all(screenWidth * 0.03),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: profileUrl.isNotEmpty
                      ? Image.network(
                          profileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/doctor1.jpeg',
                                fit: BoxFit.cover);
                          },
                        )
                      : Image.asset('assets/doctor1.jpeg', fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.0001,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Dr. $name',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Text(
                        specialization,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              degree,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.05),
                          Flexible(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
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
            'userId': currentUserId,
            'doctorId': doctorId,
            'name': name,
            'specialization': specialization,
            'degree': degree,
            'location': location,
            'slotTime': slotTime,
            'fee': fee,
            'state': state,
            'experience': experience,
            'about': about,
            'profileUrl': profileUrl,
          };
          Navigator.of(context).pushNamed(route, arguments: args);
        },
      ),
    );
  }
}

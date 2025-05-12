import 'package:flutter/material.dart';
import 'package:hosp_test/utils/config.dart';

class AppointmentTodayPage extends StatelessWidget {
  const AppointmentTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Today"),
        automaticallyImplyLeading: false,
        backgroundColor:
            Config.primaryColor, // Config.primaryColor or any color you prefer
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coming Soon Text with Styling
              Text(
                "Coming Soon",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Config
                      .primaryColor, // You can change the color as per your design
                ),
              ),
              const SizedBox(height: 20),
              // A description message or an icon to indicate coming soon
              Text(
                "The appointment scheduling feature will be available shortly. Stay tuned!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Optional Button to go back or navigate somewhere else
              SizedBox(
                width: screenWidth * 0.86,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // To go back to the previous page
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Go Back"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

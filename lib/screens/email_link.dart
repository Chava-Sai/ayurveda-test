import 'package:flutter/material.dart';
import 'package:hosp_test/components/button.dart';
import 'package:lottie/lottie.dart';

class EmailSent extends StatelessWidget {
  const EmailSent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Lottie.asset('assets/success.json'),
            ),
            Center(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: const Text(
                  'Email Verification Link \n    Successfully Sent!',
                  style: TextStyle(
                  
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            //back to home page
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Button(
                width: double.infinity,
                title: 'Back to Login Page',
                onPressed: () => Navigator.of(context).pushNamed('/'),
                disable: false,
              ),
            )
          ],
        ),
      ),
    );
  }
}

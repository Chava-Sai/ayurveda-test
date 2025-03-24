import 'package:flutter/material.dart';
import 'package:hosp_test/components/login_form.dart';
import 'package:hosp_test/components/signup_form.dart';
import 'package:hosp_test/components/social_button.dart';
import 'package:hosp_test/screens/auth_page.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:hosp_test/utils/text.dart';

class AuthUpPage extends StatefulWidget {
  const AuthUpPage({super.key});

  @override
  State<AuthUpPage> createState() => _AuthUpPageState();
}

class _AuthUpPageState extends State<AuthUpPage> {
  @override
  Widget build(BuildContext context) {
    //Config.init(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside
      },
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 25,
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Image(
                    image: AssetImage(
                      'assets/2.png',
                    ),
                    width: double.infinity,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.045),
                  Text(
                    AppText.enText['signIn_text_2']!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.045),
                  const SignUpForm(),
                 
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.04,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        AppText.enText['signIn_text_2']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      TextButton(
        onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
        },
        child: const Text(
      'Sign In',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue, // Adjust color as needed
      ),
        ),
      )
                    ],
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

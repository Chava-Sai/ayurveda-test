import 'package:flutter/material.dart';
import 'package:hosp_test/utils/config.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({Key? key, required this.social}) : super(key: key);

  final String social;

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        side: const BorderSide(width: 1, color: Colors.black),
      ),
      onPressed: () {},
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Image.asset(
              'assets/$social.png',
              width: 40,
              height: 30,
            ),
            Text(
              'Sign in with $social',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

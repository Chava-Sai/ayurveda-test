import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
class PaymentPage extends StatelessWidget {
  
  final int amount;

  const PaymentPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Page")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Scan the QR to Pay ₹$amount",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data:
                    "upi://pay?pa=rvinayk@ybl&pn=Vinay Kumar&am=$amount&cu=INR",
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "rvinayk@ybl",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "When the name 'rvinayk@ybl' appears, only then proceed with the payment.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              " 'rvinayk@ybl' ఈ పేరు కనిపించినప్పుడు మాత్రమే చెల్లింపు చేయండి",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "srinivassaichava@gmail.com",
    pass: "say2saihai",
  },
});

exports.sendVerificationEmail = functions.auth.user().onCreate(async (user) => {
  const userDoc = await admin.firestore().collection("users").doc(user.uid).get();
  if (!userDoc.exists) return null;

  const { role } = userDoc.data();
  const subject = role === "Doctor" ? "Your Profile is Under Review" : "Welcome! Verify Your Email";
  const message = role === "Doctor"
    ? "Thank you for signing up as a doctor. We are reviewing your profile."
    : "Please verify your email to complete registration.";

  return transporter.sendMail({
    from: "srinivassaichava@gmail.com",
    to: user.email,
    subject,
    text: message,
  });
});
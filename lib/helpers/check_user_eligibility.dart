import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

Future<User?> checkUserEligibilityForReschedule() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("❌ No user logged in.");
      return null;
    }

    await user.reload(); // Refresh user state
    user = FirebaseAuth.instance.currentUser; // Important after reload

    if (!user!.emailVerified) {
      debugPrint("❌ User email not verified.");
      return null;
    }

    debugPrint("✅ User is logged in and email verified.");
    return user;
  } catch (e, stackTrace) {
    debugPrint("❌ Error checking user eligibility: $e");
    debugPrint("📍 StackTrace: $stackTrace");
    return null;
  }
}

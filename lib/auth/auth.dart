import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;
  GoogleSignInAccount get user => _user!;

  Future googleLogin(BuildContext context) async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      _user = googleUser;

      if (!googleUser.email.contains("@rguktn.ac.in")) {
        await googleSignIn.disconnect();
        Fluttertoast.showToast(
          msg: "Please login with an RGUKT email.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) return;

      final userId = firebaseUser.uid;
      final email = firebaseUser.email ?? googleUser.email;
      final fullName = googleUser.displayName ?? '';

      // Split the full name into parts
      final nameParts = fullName.split(' ');
      final firstname = nameParts.isNotEmpty ? nameParts.first : '';
      final lastname = nameParts.length > 1 ? nameParts.last : '';
      final middlename = nameParts.length > 2
          ? nameParts.sublist(1, nameParts.length - 1).join(' ')
          : '';

      // Check if the user exists in the database
      final databaseRef = FirebaseDatabase.instance.ref();
      final userRef = databaseRef.child('users').child(userId).child('user');
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        // If the user doesn't exist, create the user in the database
        final userMap = {
          'userId': userId,
          'firstname': firstname,
          'middlename': middlename,
          'lastname': lastname,
          'email': email,
          'loginType': 'google',
          'accountType': 'student', // Default account type
        };

        await userRef.set(userMap);
      }

      Fluttertoast.showToast(
        msg: "Login successful.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      notifyListeners();
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Login failed: ${error.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future logout() async {
    await googleSignIn.signOut();
    FirebaseAuth.instance.signOut();
  }
}
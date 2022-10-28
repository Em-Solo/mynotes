import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

//says that this class and any subclasses of this class will be immutable
//meaning their internals will never be changed upon initialisation
@immutable
class AuthUser {
  final String? email;
  final bool isEmailVerified;

  const AuthUser({
    required this.email,
    required this.isEmailVerified,
  });

//Seems like we are creating a new method called fromFirebase takes a user object that is from firebase
//and upon calling this method you initialise an instance of AuthUser class and tu take the bool value from the
//user the firebase user. Feels like a thing we set up t obe called automatically not manuyally
  factory AuthUser.fromFirebase(User user) => AuthUser(
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
}

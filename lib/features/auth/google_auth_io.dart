// Mobile/Desktop (IO) implementation of Google Sign-In
// Uses google_sign_in v6.x API
import 'package:google_sign_in/google_sign_in.dart';

Future<Map<String, String>?> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut();
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) return null; // User cancelled
    return {
      'email': account.email,
      'name': account.displayName ?? 'Google User',
      'google_id': account.id,
    };
  } catch (e) {
    rethrow;
  }
}

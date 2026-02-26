// google_sign_in_stub.dart
// Fallback for unsupported platforms (e.g., Windows Desktop)
class GoogleSignIn {
  GoogleSignIn({List<String>? scopes});
  Future<dynamic> signIn() async => null;
}
class GoogleSignInAccount {
  String get email => '';
  String? get displayName => null;
  String get id => '';
}

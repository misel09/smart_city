// This file uses conditional imports to load the correct platform implementation.
// On web, it loads a stub. On mobile (io), it loads the real google_sign_in.
export 'google_auth_io.dart'
  if (dart.library.html) 'google_auth_web.dart';

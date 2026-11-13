import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The release build only gets the permissions of the main manifest: without INTERNET,
/// every Supabase call fails and sign-in shows « Vérifiez votre réseau ».
void main() {
  test('the release manifest declares the network permissions', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
  });
}

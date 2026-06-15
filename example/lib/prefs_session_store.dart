import 'package:ichibase/ichibase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A realistic [SessionStore] backed by `shared_preferences`, so the signed-in
/// session survives an app restart.
///
/// The SDK's default store is in-memory (lost on restart). Pass an instance of
/// this to `Ichibase.createClient(..., store: PrefsSessionStore())` and call
/// `await ichi.loadSession()` once at startup to rehydrate.
///
/// Note: `shared_preferences` is plain, unencrypted storage. A production app
/// holding long-lived refresh tokens should prefer `flutter_secure_storage`
/// (Keychain / Keystore). The [SessionStore] contract is identical, so swapping
/// the implementation is a one-line change.
class PrefsSessionStore implements SessionStore {
  @override
  Future<String?> getItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setItem(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> removeItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Initialize Firebase for tests.
///
/// Screens that directly create `DatabaseService()` (i.e., call
/// `FirestoreService.instance` which calls `FirebaseFirestore.instance`)
/// require Firebase to be initialized before the widget tree is built.
///
/// Call this in `setUpAll()` of any test file that tests such screens.
Future<void> setupFirebaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'mock-project-id',
      ),
    );
  } catch (_) {
    // Firebase already initialized
  }
}

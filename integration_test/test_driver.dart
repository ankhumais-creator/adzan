import 'package:integration_test/integration_test.dart';

/// Integration test driver for running all integration tests
/// Run with: flutter test integration_test/
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Tests are defined in individual test files:
  // - app_test.dart: App startup and provider accessibility
  // - prayer_flow_test.dart: Prayer times calculation and tasbih flow
  
  // To run all integration tests:
  // flutter test integration_test/
  
  // To run a specific test file:
  // flutter test integration_test/app_test.dart
  // flutter test integration_test/prayer_flow_test.dart
  
  // To run with a connected device:
  // flutter test integration_test/ -d <device_id>
}

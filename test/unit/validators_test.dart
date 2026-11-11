import 'package:flutter_test/flutter_test.dart';
import 'package:nexhelp/core/config/app_config.dart';
import 'package:nexhelp/core/validation/validators.dart';

void main() {
  group('Validators', () {
    test('validateFullName', () {
      expect(Validators.validateFullName(null), isNotNull);
      expect(Validators.validateFullName(''), isNotNull);
      expect(Validators.validateFullName('A'), isNotNull);
      expect(Validators.validateFullName('Rajesh Kumar'), isNull);
    });

    test('validateEmail', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('invalid'), isNotNull);
      expect(Validators.validateEmail('user@test'), isNotNull);
      expect(Validators.validateEmail('user@example.com'), isNull);
    });

    test('validatePassword', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('securePass123'), isNull);
    });

    test('validatePhone', () {
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('+919876543210'), isNull);
    });

    test('validatePincode enforces Bengaluru pilot area', () {
      expect(Validators.validatePincode(null), isNotNull);
      expect(Validators.validatePincode('123'), isNotNull);
      expect(
        Validators.validatePincode('110001'),
        equals('NexHelp currently serves pincode 560102 (HSR Layout focus).'),
      );
      expect(Validators.validatePincode(AppConfig.pilotPincode), isNull);
    });

    test('validateDescription enforces minimum 10 chars', () {
      expect(Validators.validateDescription(null), isNotNull);
      expect(Validators.validateDescription('Short'), isNotNull);
      expect(
        Validators.validateDescription('Pipe leaking in kitchen sink'),
        isNull,
      );
    });

    test('validateAddress enforces minimum 5 chars', () {
      expect(Validators.validateAddress(null), isNotNull);
      expect(Validators.validateAddress('abc'), isNotNull);
      expect(
        Validators.validateAddress('Flat 302, Green Glen Apartments'),
        isNull,
      );
    });

    test('validateExperienceYears', () {
      expect(Validators.validateExperienceYears(null), isNotNull);
      expect(Validators.validateExperienceYears('-1'), isNotNull);
      expect(Validators.validateExperienceYears('75'), isNotNull);
      expect(Validators.validateExperienceYears('5'), isNull);
    });
  });
}

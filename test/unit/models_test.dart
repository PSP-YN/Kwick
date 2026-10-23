import 'package:flutter_test/flutter_test.dart';
import 'package:nexhelp/shared/models/assignment.dart';
import 'package:nexhelp/shared/models/service_category.dart';
import 'package:nexhelp/shared/models/service_request.dart';
import 'package:nexhelp/shared/models/user_profile.dart';
import 'package:nexhelp/shared/models/user_role.dart';

void main() {
  group('Domain Models Serialization', () {
    test('UserProfile model handles json safely', () {
      final json = {
        'id': 'u1',
        'full_name': 'Alice Smith',
        'phone': '9876543210',
        'email': 'alice@example.com',
        'avatar_path': null,
        'account_status': 'active',
        'created_at': '2026-10-23T10:00:00.000Z',
        'updated_at': '2026-10-23T10:00:00.000Z',
      };

      final profile = UserProfile.fromJson(json, [UserRole.customer]);
      expect(profile.id, 'u1');
      expect(profile.fullName, 'Alice Smith');
      expect(profile.isActive, isTrue);
      expect(profile.isProvider, isFalse);
    });

    test('ServiceCategory model serialization', () {
      final json = {
        'id': 'c1',
        'name': 'Plumbing',
        'slug': 'plumbing',
        'description': 'Tap & drain fixes',
        'icon_key': 'plumbing',
        'is_active': true,
        'sort_order': 1,
      };

      final cat = ServiceCategory.fromJson(json);
      expect(cat.name, 'Plumbing');
      expect(cat.slug, 'plumbing');
      expect(cat.isActive, isTrue);
    });

    test('ServiceRequest parses monetary paise and timestamps', () {
      final json = {
        'id': 'r1',
        'customer_id': 'c1',
        'category_id': 'cat1',
        'service_area_id': 'area1',
        'description': 'Water leak from bathroom flush valve',
        'address_line': '#101, HSR Layout',
        'pincode': '560102',
        'status': 'assigned',
        'quoted_price_minor': 35000,
        'final_price_minor': null,
        'created_at': '2026-10-23T12:00:00.000Z',
        'updated_at': '2026-10-23T12:00:00.000Z',
      };

      final req = ServiceRequest.fromJson(json);
      expect(req.quotedPriceMinor, 35000);
      expect(req.status, OrderStatus.assigned);
    });

    test('Assignment model parses status and joined provider name', () {
      final json = {
        'id': 'a1',
        'request_id': 'r1',
        'provider_id': 'p1',
        'status': 'offered',
        'assigned_at': '2026-10-23T12:30:00.000Z',
        'providers': {
          'profiles': {'full_name': 'Rajesh Plumber', 'phone': '9876543213'},
        },
      };

      final assignment = Assignment.fromJson(json);
      expect(assignment.providerName, 'Rajesh Plumber');
      expect(assignment.providerPhone, '9876543213');
      expect(assignment.status, AssignmentStatus.offered);
    });
  });
}

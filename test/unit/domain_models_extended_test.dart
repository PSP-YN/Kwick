import 'package:flutter_test/flutter_test.dart';
import 'package:nexhelp/shared/models/user_profile.dart';
import 'package:nexhelp/shared/models/user_role.dart';
import 'package:nexhelp/shared/models/assignment.dart';
import 'package:nexhelp/shared/models/provider_profile.dart';
import 'package:nexhelp/shared/models/review.dart';
import 'package:nexhelp/shared/models/support_ticket.dart';
import 'package:nexhelp/shared/models/service_area.dart';

void main() {
  group('Extended Domain Models Tests', () {
    test('UserProfile round-trip serialization', () {
      final user = UserProfile(
        id: 'usr-123',
        fullName: 'Aarav Patel',
        phone: '+919876543210',
        roles: const [UserRole.customer],
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final json = user.toJson();
      expect(json['full_name'], equals('Aarav Patel'));
      expect(user.roles.contains(UserRole.customer), isTrue);

      final restored = UserProfile.fromJson(json, [UserRole.customer]);
      expect(restored.id, equals('usr-123'));
      expect(restored.roles, contains(UserRole.customer));
    });

    test('ProviderProfile parses experience, rating and status correctly', () {
      final json = {
        'id': 'pro-456',
        'profile_id': 'usr-pro-01',
        'experience_years': 6,
        'verification_status': 'approved',
        'availability_status': 'available',
        'verification_notes': 'Aadhaar checked',
        'created_at': '2026-10-01T10:00:00Z',
      };

      final profile = ProviderProfile.fromJson(json);
      expect(profile.experienceYears, equals(6));
      expect(profile.verificationStatus, equals(VerificationStatus.approved));
      expect(profile.availabilityStatus, equals(AvailabilityStatus.available));
      expect(profile.isApproved, isTrue);
      expect(profile.isAvailable, isTrue);
    });

    test('Assignment model status parsing and toJson', () {
      final json = {
        'id': 'asg-789',
        'request_id': 'req-101',
        'provider_id': 'pro-456',
        'status': 'accepted',
        'assigned_at': '2026-10-23T10:00:00Z',
        'responded_at': '2026-10-23T10:02:00Z',
      };

      final assignment = Assignment.fromJson(json);
      expect(assignment.status, equals(AssignmentStatus.accepted));
      expect(assignment.providerId, equals('pro-456'));

      final out = assignment.toJson();
      expect(out['status'], equals('accepted'));
    });

    test('Review model validation and serialization', () {
      final review = Review(
        id: 'rev-01',
        customerId: 'cust-01',
        requestId: 'req-101',
        providerId: 'pro-01',
        rating: 5,
        comment: 'Excellent plumbing work, very professional and clean.',
        createdAt: DateTime.now(),
      );

      final json = review.toJson();
      expect(json['rating'], equals(5));
      expect(json['comment'], contains('clean'));

      final restored = Review.fromJson(json);
      expect(restored.rating, equals(5));
      expect(restored.comment, equals(review.comment));
    });

    test('SupportTicket model parses status and role correctly', () {
      final json = {
        'id': 'tkt-01',
        'request_id': 'req-101',
        'user_id': 'cust-01',
        'issue_category': 'delay',
        'description': 'Partner is delayed by 15 mins due to rain.',
        'status': 'open',
        'created_at': '2026-10-23T11:00:00Z',
      };

      final ticket = SupportTicket.fromJson(json);
      expect(ticket.issueCategory, equals('delay'));
      expect(ticket.status, equals('open'));

      final out = ticket.toJson();
      expect(out['issue_category'], equals('delay'));
    });

    test('ServiceArea model pilot pincode validation', () {
      final area = ServiceArea(
        id: 'area-blr-01',
        name: 'Bengaluru South (HSR & Koramangala)',
        pincode: '560102',
        city: 'Bengaluru',
        state: 'Karnataka',
        isActive: true,
      );

      expect(area.pincode, equals('560102'));
      expect(area.isActive, isTrue);
    });
  });
}

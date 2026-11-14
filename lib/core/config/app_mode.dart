import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_role.dart';

enum KwickAppMode { customer, provider }

extension KwickAppModeX on KwickAppMode {
  UserRole get role =>
      this == KwickAppMode.provider ? UserRole.provider : UserRole.customer;

  String get displayName =>
      this == KwickAppMode.provider ? 'Kwick Partner' : 'Kwick';

  String get accountLabel =>
      this == KwickAppMode.provider ? 'service partner' : 'customer';
}

final kwickAppModeProvider = Provider<KwickAppMode>(
  (ref) => KwickAppMode.customer,
);

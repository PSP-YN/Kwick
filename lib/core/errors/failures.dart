/// Domain failure classes for robust, typed error handling across Kwick
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});

  factory NetworkFailure.noConnection() => const NetworkFailure(
    'Unable to connect to Kwick servers. Please verify your internet connection.',
    code: 'NETWORK_UNAVAILABLE',
  );
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  factory ServerFailure.unexpected() => const ServerFailure(
    'An unexpected server error occurred. Please try again shortly.',
    code: 'INTERNAL_ERROR',
  );
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});

  factory PermissionFailure.unauthorized() => const PermissionFailure(
    'You do not have permission to perform this action.',
    code: 'FORBIDDEN',
  );
}

class ConcurrencyFailure extends Failure {
  const ConcurrencyFailure(super.message, {super.code});

  factory ConcurrencyFailure.assignmentConflict() => const ConcurrencyFailure(
    'This request has already been assigned or updated by another operator.',
    code: 'ASSIGNMENT_CONFLICT',
  );
}

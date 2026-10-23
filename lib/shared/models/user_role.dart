/// Valid user roles in NexHelp
enum UserRole {
  customer('customer', 'Customer'),
  provider('provider', 'Service Provider'),
  admin('admin', 'Operations Admin'),
  superAdmin('super_admin', 'Super Admin');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String val) {
    switch (val) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}

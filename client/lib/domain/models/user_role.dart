/// What a person is allowed to do.
enum UserRole {
  employee('employee', 'Employee'),
  staff('staff', 'IT Staff'),
  admin('admin', 'Admin');

  const UserRole(this.wire, this.label);

  final String wire;
  final String label;

  static UserRole fromWire(String value) => values.firstWhere(
    (role) => role.wire == value,
    orElse: () => throw FormatException('Unknown role: $value'),
  );

  /// Only IT staff and admins may assign a request or change its status.
  bool get isSupportStaff => this != UserRole.employee;
}

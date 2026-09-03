enum UserRole {
  employee('employee', 'Employee'),
  staff('staff', 'IT Staff'),
  admin('admin', 'Admin');

  const UserRole(this.wire, this.label);

  final String wire;
  final String label;

  static UserRole? tryFromWire(String? value) {
    for (final role in values) {
      if (role.wire == value) return role;
    }
    return null;
  }

  static UserRole fromWire(String value) {
    return tryFromWire(value) ??
        (throw FormatException('Unknown role: $value'));
  }

  bool get isSupportStaff => this != UserRole.employee;
}

import 'package:app/utils/json.dart';

enum UserRole implements WireEnum {
  employee('employee', 'Employee'),
  staff('staff', 'IT Staff'),
  admin('admin', 'Admin');

  const UserRole(this.wire, this.label);

  @override
  final String wire;
  final String label;

  static UserRole? tryFromWire(String? value) => values.tryByWire(value);

  static UserRole fromWire(String value) => values.byWire(value, label: 'role');

  bool get isSupportStaff => this != UserRole.employee;
}

class UserRoleConverter extends WireConverter<UserRole> {
  const UserRoleConverter();

  @override
  UserRole fromJson(String json) => UserRole.fromWire(json);
}

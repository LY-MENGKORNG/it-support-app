import 'package:flutter/material.dart';

import 'package:app/domain/models/user.dart';

/// Square, like everything else in this app, and coloured deterministically
/// from the user's id so the same person always looks the same.
class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, this.size = 36});

  final User user;
  final double size;

  static const _palette = [
    Color(0xFF4C8DFF),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFFF59E0B),
    Color(0xFF38BDF8),
    Color(0xFFF472B6),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[user.id % _palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        user.initials,
        style: TextStyle(
          color: color,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

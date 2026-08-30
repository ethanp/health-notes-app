import 'package:flutter/material.dart';
import 'package:health_notes/utils/auth_utils.dart';

class const LogOutButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => AuthUtils.showSignOutDialog(context),
      child: const Text('Log out'),
    );
  }
}

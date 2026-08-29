import 'package:flutter/material.dart';
import 'package:health_notes/utils/auth_utils.dart';

class LogOutButton extends StatelessWidget {
  const LogOutButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => AuthUtils.showSignOutDialog(context),
      child: const Text('Log out'),
    );
  }
}

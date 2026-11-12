import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_role.dart';
import '../application/session.dart';
import 'auth_widgets.dart';
import 'password_choice_form.dart';

/// First sign-in: choose a new password (content of the web prototype
/// « 3 · Lien ouvert (aussi : première connexion) », laid out like Mobile · Connexion).
class NewPasswordScreen extends ConsumerWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthScaffold(
      form: PasswordChoiceForm(
        onSave: (password, confirmation) async {
          await ref.read(sessionProvider.notifier).setPassword(password, confirmation);
          final profile = ref.read(sessionProvider);
          if (context.mounted && profile != null) context.go(homeRouteFor(profile.roles));
        },
      ),
      footer: const AuthHelpFooter(),
    );
  }
}

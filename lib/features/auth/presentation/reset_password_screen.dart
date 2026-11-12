import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_role.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../application/session.dart';
import 'auth_widgets.dart';
import 'password_choice_form.dart';

/// Page opened by the reset link of the e-mail (web `reinitialiser-mot-de-passe`):
/// new password, « Mot de passe enregistré » or « Lien expiré ».
class ResetPasswordScreen extends ConsumerWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(passwordRecoveryProvider);
    final recovery = ref.read(passwordRecoveryProvider.notifier);

    void leave(String route) {
      recovery.clear();
      context.go(route);
    }

    final Widget form = switch (status) {
      RecoveryStatus.ready => PasswordChoiceForm(onSave: recovery.resetPassword),
      RecoveryStatus.done => _Message(
          title: 'Mot de passe enregistré',
          text: 'Votre nouveau mot de passe est actif. Connectez-vous avec celui-ci.',
          action: 'Aller à la connexion',
          onPressed: () => leave(Routes.login),
        ),
      RecoveryStatus.none || RecoveryStatus.invalid => _Message(
          title: 'Lien expiré',
          text: 'Ce lien de réinitialisation n’est plus valable (il expire au bout de '
              '${AuthConfig.resetLinkValidityHours} heure et ne sert qu’une fois). Demandez-en un nouveau.',
          action: 'Demander un nouveau lien',
          onPressed: () => leave(Routes.forgotPassword),
        ),
    };
    return AuthScaffold(form: form, footer: const AuthHelpFooter());
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.text, required this.action, required this.onPressed});

  final String title;
  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: parcText(22, weight: 800))),
        const SizedBox(height: 6),
        Text(text, style: parcText(15, color: ParcColors.textMuted, height: 1.5)),
        const SizedBox(height: 20),
        ParcPrimaryButton(label: action, onPressed: onPressed),
      ],
    );
  }
}

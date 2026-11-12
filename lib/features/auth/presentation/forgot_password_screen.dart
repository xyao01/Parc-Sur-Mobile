import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_role.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../application/session.dart';
import '../domain/login_failure.dart';
import 'auth_widgets.dart';
import 'password_choice_form.dart';

/// « Mot de passe oublié » — content of the web prototype (§ 1-2), laid out like Mobile · Connexion.
/// Sends the Supabase reset e-mail; its link reopens the app on the reset page.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _sentTo;

  static const _hours = AuthConfig.resetLinkValidityHours;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _sentTo = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .requestPasswordReset(_email.text, redirectTo: ref.read(passwordResetRedirectProvider));
      if (mounted) setState(() => _sentTo = _email.text.trim().toLowerCase());
    } on LoginFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = const UnexpectedFailure().message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              link: true,
              child: InkWell(
                onTap: () => context.go(Routes.login),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ParcIcon(ParcIcons.back, size: 16, color: ParcColors.primary),
                      const SizedBox(width: 4),
                      Text('Retour à la connexion', style: parcText(14, weight: 700, color: ParcColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(header: true, child: Text('Mot de passe oublié', style: parcText(22, weight: 800))),
          const SizedBox(height: 6),
          Text(
            'Saisissez votre adresse e-mail : vous recevrez un lien pour choisir un nouveau mot de passe, '
            'valable $_hours heure.',
            style: parcText(15, color: ParcColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          ParcLabeled(
            label: 'Adresse e-mail',
            child: ParcTextField(
              key: const Key('forgot.email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.done,
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 16), ParcErrorAlert(message: _error!)],
          const SizedBox(height: 20),
          ParcPrimaryButton(label: 'Recevoir le lien', onPressed: _busy ? null : _send),
          Semantics(
            liveRegion: true,
            child: _sentTo == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Si un compte existe pour $_sentTo, un e-mail vient d’être envoyé. '
                      'Le lien est valable $_hours heure : ouvrez-le sur ce téléphone.',
                      style: parcText(14, color: ParcColors.success, height: 1.5),
                    ),
                  ),
          ),
        ],
      ),
      footer: const AuthHelpFooter(),
    );
  }
}

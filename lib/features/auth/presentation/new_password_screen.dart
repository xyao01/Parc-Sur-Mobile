import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_role.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../application/session.dart';
import '../domain/login_failure.dart';
import '../domain/password_policy.dart';
import 'auth_widgets.dart';

/// First sign-in: choose a new password (content of the web prototype
/// « 3 · Lien ouvert (aussi : première connexion) », laid out like Mobile · Connexion).
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionProvider.notifier);
      await session.setPassword(_password.text, _confirmation.text);
      final profile = ref.read(sessionProvider);
      if (mounted && profile != null) context.go(homeRouteFor(profile.roles));
    } on LoginFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = const PasswordNotSaved().message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Nouveau mot de passe', style: parcText(22, weight: 800))),
            const SizedBox(height: 6),
            Text(
              'Choisissez votre nouveau mot de passe.',
              style: parcText(15, color: ParcColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 16),
            ParcLabeled(
              label: 'Nouveau mot de passe',
              child: PasswordField(
                key: const Key('newPassword.password'),
                controller: _password,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            _Criteria(password: _password.text),
            const SizedBox(height: 16),
            ParcLabeled(
              label: 'Confirmer le mot de passe',
              child: PasswordField(
                key: const Key('newPassword.confirmation'),
                controller: _confirmation,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
              ),
            ),
            if (_error != null) ...[const SizedBox(height: 16), ParcErrorAlert(message: _error!)],
            const SizedBox(height: 20),
            ParcPrimaryButton(label: 'Enregistrer le mot de passe', onPressed: _busy ? null : _save),
          ],
        ),
      ),
      footer: Text(
        "Besoin d'aide ? Contactez l'administrateur de ParcSûr.",
        textAlign: TextAlign.center,
        style: parcText(13, color: ParcColors.textMuted, height: 1.5),
      ),
    );
  }
}

/// « Règles du mot de passe », ticked as the user types (✓ green, ○ grey).
class _Criteria extends StatelessWidget {
  const _Criteria({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Règles du mot de passe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in PasswordPolicy.criteria(password))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      c.ok ? '✓' : '○',
                      style: parcText(14, color: c.ok ? ParcColors.success : ParcColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.label,
                    semanticsLabel: '${c.label}${c.ok ? ', respecté' : ''}',
                    style: parcText(14, color: c.ok ? ParcColors.success : ParcColors.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

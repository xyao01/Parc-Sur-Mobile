import 'package:flutter/material.dart';

import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../domain/login_failure.dart';
import '../domain/password_policy.dart';
import 'auth_widgets.dart';

/// « Nouveau mot de passe » form (web prototype « 3 · Lien ouvert (aussi : première connexion) »),
/// shared by the first sign-in and the reset link pages.
class PasswordChoiceForm extends StatefulWidget {
  const PasswordChoiceForm({super.key, required this.onSave});

  /// Saves the password; throws a [LoginFailure] shown under the fields.
  final Future<void> Function(String password, String confirmation) onSave;

  @override
  State<PasswordChoiceForm> createState() => _PasswordChoiceFormState();
}

class _PasswordChoiceFormState extends State<PasswordChoiceForm> {
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
      await widget.onSave(_password.text, _confirmation.text);
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
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('Nouveau mot de passe', style: parcText(22, weight: 800))),
          const SizedBox(height: 6),
          Text('Choisissez votre nouveau mot de passe.', style: parcText(15, color: ParcColors.textMuted, height: 1.5)),
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

/// « Besoin d'aide ? » footer of the sign-in pages (Mobile · Connexion).
class AuthHelpFooter extends StatelessWidget {
  const AuthHelpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "Besoin d'aide ? Contactez l'administrateur de ParcSûr.",
      textAlign: TextAlign.center,
      style: parcText(13, color: ParcColors.textMuted, height: 1.5),
    );
  }
}

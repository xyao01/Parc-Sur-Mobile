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

/// Mobile · Connexion — signs in against Supabase (see `AuthService`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await ref.read(sessionProvider.notifier).signIn(_email.text, _password.text);
      if (!mounted) return;
      // Account created with the default password: change it before entering (as on the web).
      context.go(profile.mustChangePassword ? Routes.newPassword : homeRouteFor(profile.roles));
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
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Connexion', style: parcText(22, weight: 800))),
            const SizedBox(height: 16),
            ParcLabeled(
              label: 'Adresse e-mail',
              child: ParcTextField(
                key: const Key('login.email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: 16),
            ParcLabeled(
              label: 'Mot de passe',
              child: PasswordField(
                key: const Key('login.password'),
                controller: _password,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                link: true,
                child: InkWell(
                  onTap: () => context.go(Routes.forgotPassword),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: parcText(14, weight: 700, color: ParcColors.primary).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: ParcColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[const SizedBox(height: 16), ParcErrorAlert(message: _error!)],
            const SizedBox(height: 20),
            ParcPrimaryButton(label: 'Se connecter', onPressed: _busy ? null : _signIn),
            const SizedBox(height: 16),
            ParcOutlinedButton(
              label: "Utiliser l'empreinte digitale",
              // Biometric unlock not wired yet (see README).
              onPressed: () {},
              leading: const ParcIcon(ParcIcons.fingerprint, color: ParcColors.primary),
            ),
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

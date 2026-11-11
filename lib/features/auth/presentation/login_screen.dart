import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_role.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../../../core/widgets/parcsur_logo.dart';

/// Mobile · Connexion.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    // Authentication is not wired yet (Supabase, see README): route by configured role.
    context.go(homeRouteFor(ref.read(currentRoleProvider)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Hero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text('Connexion', style: parcText(22, weight: 800))),
                        const SizedBox(height: 16),
                        ParcLabeled(
                          label: 'Adresse e-mail',
                          child: ParcTextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ParcLabeled(
                          label: 'Mot de passe',
                          child: ParcTextField(
                            key: const Key('login.password'),
                            controller: _password,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            padding: const EdgeInsets.only(left: 14, right: 4),
                            trailing: Semantics(
                              button: true,
                              label: _showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                              excludeSemantics: true,
                              child: InkWell(
                                onTap: () => setState(() => _showPassword = !_showPassword),
                                borderRadius: BorderRadius.circular(10),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(child: ParcIcon(ParcIcons.eye, size: 20, color: ParcColors.textMuted)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            link: true,
                            child: InkWell(
                              // Mobile reset flow not designed yet (see README).
                              onTap: () {},
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
                        const SizedBox(height: 20),
                        ParcPrimaryButton(label: 'Se connecter', onPressed: _signIn),
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
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 28 + MediaQuery.paddingOf(context).bottom),
                  child: Text(
                    "Besoin d'aide ? Contactez l'administrateur de ParcSûr.",
                    textAlign: TextAlign.center,
                    style: parcText(13, color: ParcColors.textMuted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(28, 64 + top, 28, 40),
      decoration: const BoxDecoration(
        color: ParcColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: ParcColors.primary, borderRadius: BorderRadius.circular(22)),
            alignment: Alignment.center,
            child: const ParcSurMark(size: 62),
          ),
          const SizedBox(height: 14),
          const ParcSurWordmark(fontSize: 30, letterSpacing: -0.5),
          const SizedBox(height: 14),
          Text('La gestion du parc, en toute sérénité.', style: parcText(14, color: ParcColors.onDarkMuted)),
        ],
      ),
    );
  }
}

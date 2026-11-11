import 'package:flutter/material.dart';

import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../../../core/widgets/parcsur_logo.dart';

/// Navy header with logo, wordmark and tagline (Mobile · Connexion).
class AuthHero extends StatelessWidget {
  const AuthHero({super.key});

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

/// Page layout shared by the sign-in screens: hero, form, footer pinned at the bottom.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.form, this.footer});

  final Widget form;
  final Widget? footer;

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
                const AuthHero(),
                Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 16), child: form),
                const Spacer(),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 28 + MediaQuery.paddingOf(context).bottom),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Password input with the show / hide eye button.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return ParcTextField(
      controller: widget.controller,
      obscureText: !_visible,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      padding: const EdgeInsets.only(left: 14, right: 4),
      trailing: Semantics(
        button: true,
        label: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => setState(() => _visible = !_visible),
          borderRadius: BorderRadius.circular(10),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(child: ParcIcon(ParcIcons.eye, size: 20, color: ParcColors.textMuted)),
          ),
        ),
      ),
    );
  }
}

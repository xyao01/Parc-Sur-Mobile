import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/password_choice_form.dart';
import '../../missions/presentation/journey_widgets.dart';

/// Profile › « Changer mon mot de passe »: same form and policy as the first sign-in (Supabase Auth `updateUser`).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  bool _done = false;

  void _back() => context.canPop() ? context.pop() : context.go(Routes.profile);

  @override
  Widget build(BuildContext context) {
    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Changer mon mot de passe',
        subtitle: 'Profil',
        backLabel: 'Retour au profil',
        onBack: _back,
      ),
      bodyPadding: EdgeInsets.fromLTRB(20, _done ? 40 : 20, 20, 20),
      body: _done
          ? ResultView(
              icon: ParcIcons.checkBold,
              iconBg: ParcColors.successBg,
              iconColor: ParcColors.success,
              topPadding: 18,
              title: 'Mot de passe modifié',
              message: Text(
                'Votre mot de passe a été modifié.',
                textAlign: TextAlign.center,
                style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
              ),
            )
          : PasswordChoiceForm(
              onSave: (password, confirmation) async {
                await ref.read(sessionProvider.notifier).setPassword(password, confirmation);
                if (mounted) setState(() => _done = true);
              },
            ),
      footer: _done ? [ParcPrimaryButton(label: 'Retour au profil', onPressed: _back)] : null,
    );
  }
}

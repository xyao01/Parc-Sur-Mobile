import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../../auth/application/session.dart';
import '../../auth/domain/mobile_profile.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/profile_gateway.dart';
import '../data/profile_providers.dart';

/// « Mes coordonnées » sheet (Mob-P01): saved with `modifier_mon_compte`.
Future<void> showAccountSheet(BuildContext context, {required MobileProfile profile, AccountDetails? details}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: ParcColors.scrim,
    builder: (_) => _AccountSheet(profile: profile, details: details),
  );
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet({required this.profile, this.details});

  final MobileProfile profile;
  final AccountDetails? details;

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  late final _firstName = TextEditingController(text: widget.profile.firstName);
  late final _lastName = TextEditingController(text: widget.profile.lastName);
  late final _phone = TextEditingController(text: widget.details?.phone ?? '');
  late final _location = TextEditingController(text: widget.details?.location ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _location.dispose();
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
      await ref.read(profileGatewayProvider).updateMyAccount(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phone: _phone.text.trim(),
            location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          );
      ref.read(sessionProvider.notifier).rename(_firstName.text, _lastName.text);
      ref.invalidate(accountDetailsProvider);
      if (mounted) Navigator.of(context).pop();
    } on ProfileGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Vos coordonnées n’ont pas pu être enregistrées. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String label, Key key, TextEditingController c, {TextInputType? type, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: label, style: parcText(13, weight: 700)),
          if (suffix != null) TextSpan(text: ' $suffix', style: parcText(13, weight: 600, color: ParcColors.textMuted)),
        ])),
        const SizedBox(height: 6),
        ParcTextField(key: key, controller: c, height: 48, fontSize: 15, keyboardType: type),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Semantics(
        container: true,
        label: 'Mes coordonnées',
        child: Container(
          decoration: const BoxDecoration(
            color: ParcColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.paddingOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Semantics(header: true, child: Text('Mes coordonnées', style: parcText(18, weight: 800)))),
                    Semantics(
                      button: true,
                      label: 'Fermer',
                      excludeSemantics: true,
                      child: Material(
                        color: ParcColors.dividerSoft,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(child: ParcIcon(ParcIcons.cross, size: 18, color: ParcColors.text)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field('Prénom', const Key('account.firstName'), _firstName)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Nom', const Key('account.lastName'), _lastName)),
                  ],
                ),
                const SizedBox(height: 14),
                _field('Téléphone', const Key('account.phone'), _phone, type: TextInputType.phone),
                const SizedBox(height: 14),
                _field('Localisation', const Key('account.location'), _location, suffix: '(facultatif)'),
                if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
                const SizedBox(height: 14),
                JourneyActionButton(label: 'Enregistrer', busy: _busy, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

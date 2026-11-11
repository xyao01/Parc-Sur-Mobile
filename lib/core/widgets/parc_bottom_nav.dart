import 'package:flutter/material.dart';

import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';
import 'parc_icon.dart';

class ParcNavItem {
  const ParcNavItem({required this.label, required this.icon, this.onTap});

  final String label;
  final String icon;
  final VoidCallback? onTap;
}

/// Bottom tab bar from the prototype (white, 1 px top border, 4 tabs).
class ParcBottomNav extends StatelessWidget {
  const ParcBottomNav({super.key, required this.items, required this.currentIndex});

  final List<ParcNavItem> items;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Semantics(
      container: true,
      label: 'Navigation',
      child: Container(
        decoration: const BoxDecoration(
          color: ParcColors.surface,
          border: Border(top: BorderSide(color: ParcColors.divider)),
        ),
        padding: EdgeInsets.fromLTRB(8, 6, 8, 14 + bottomInset),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) Expanded(child: _Tab(item: items[i], selected: i == currentIndex)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected});

  final ParcNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ParcColors.primary : ParcColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: item.onTap ?? () {},
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ParcIcon(item.icon, color: color),
              const SizedBox(height: 2),
              Text(item.label, style: parcText(11, weight: selected ? 800 : 600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

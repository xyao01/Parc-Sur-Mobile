import 'package:flutter/material.dart';

import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';

/// Shared outline for prototype inputs: white fill, 1.5 px #D5DEE8 border.
BoxDecoration parcFieldDecoration({double radius = 12, Color border = ParcColors.inputBorder}) => BoxDecoration(
      color: ParcColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 1.5),
    );

/// Label above an input, as in the prototype (`<label>` + bold caption, gap 6).
class ParcLabeled extends StatelessWidget {
  const ParcLabeled({super.key, required this.label, required this.child, this.labelSize = 14, this.labelWeight = 700});

  final String label;
  final Widget child;
  final double labelSize;
  final int labelWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: parcText(labelSize, weight: labelWeight)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Bordered text input with optional trailing widget (eye button, unit…).
class ParcTextField extends StatelessWidget {
  const ParcTextField({
    super.key,
    this.controller,
    this.height = 52,
    this.radius = 12,
    this.fontSize = 16,
    this.fontWeight = 400,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.trailing,
    this.borderColor = ParcColors.inputBorder,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.maxLines = 1,
    this.hintText,
    this.onChanged,
    this.textInputAction,
    this.semanticLabel,
    this.focusNode,
  });

  final TextEditingController? controller;
  final double? height;
  final double radius;
  final double fontSize;
  final int fontWeight;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final Widget? trailing;
  final Color borderColor;
  final EdgeInsets padding;
  final int maxLines;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      maxLines: maxLines,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: parcText(fontSize, weight: fontWeight),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: parcText(fontSize, color: ParcColors.textMuted),
      ),
    );
    return Semantics(
      label: semanticLabel,
      child: Container(
        height: height,
        padding: padding,
        decoration: parcFieldDecoration(radius: radius, border: borderColor),
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: maxLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [Expanded(child: field), ?trailing],
        ),
      ),
    );
  }
}

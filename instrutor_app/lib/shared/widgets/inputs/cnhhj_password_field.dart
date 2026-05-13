import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Campo de senha com ícone de "olho" para mostrar/ocultar.
class CnhhjPasswordField extends StatefulWidget {
  const CnhhjPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint = 'Digite sua senha',
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? label;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<CnhhjPasswordField> createState() => _CnhhjPasswordFieldState();
}

class _CnhhjPasswordFieldState extends State<CnhhjPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 20,
              color: AppColors.textMuted,
            ),
            suffixIcon: IconButton(
              tooltip: _obscured ? 'Mostrar' : 'Ocultar',
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: Icon(
                _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

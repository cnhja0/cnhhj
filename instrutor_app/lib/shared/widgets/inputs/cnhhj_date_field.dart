import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';

/// Campo de data no formato DD/MM/AAAA com picker nativo ao tocar.
class CnhhjDateField extends StatefulWidget {
  const CnhhjDateField({
    super.key,
    this.label,
    this.hint = 'DD/MM/AAAA',
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.errorText,
  });

  final String? label;
  final String hint;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final String? errorText;

  @override
  State<CnhhjDateField> createState() => _CnhhjDateFieldState();
}

class _CnhhjDateFieldState extends State<CnhhjDateField> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.initialDate));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(DateTime? d) =>
      d == null ? '' : DateFormat('dd/MM/yyyy').format(d);

  Future<void> _open() async {
    final DateTime now = DateTime.now();
    final DateTime picked = (await showDatePicker(
          context: context,
          initialDate: widget.initialDate ?? DateTime(now.year - 25),
          firstDate: widget.firstDate ?? DateTime(1900),
          lastDate: widget.lastDate ?? now,
          locale: const Locale('pt', 'BR'),
        )) ??
        widget.initialDate ??
        DateTime(now.year - 25);
    _controller.text = _format(picked);
    widget.onChanged?.call(picked);
  }

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
          controller: _controller,
          readOnly: true,
          onTap: _open,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Formatter para entrada manual no formato DD/MM/AAAA (caso queira permitir
/// digitação no futuro). Não usado por padrão.
class BrDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}

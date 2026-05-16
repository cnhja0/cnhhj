import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// Item exibido pelo picker. Fica genérico (id + label) para o caller
/// converter de qualquer tipo (FipeItem, enum, etc.).
class PickerItem<T> {
  const PickerItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// Campo "select com busca" — visualmente parece o `CnhhjDropdown`, mas
/// ao toque abre um bottom sheet com lista + caixa de busca. Resolve o
/// problema de dropdowns gigantes (FIPE tem ~75 marcas, ~500 modelos).
///
/// Estados:
///   • `loading: true` mostra spinner em vez da lista
///   • `error != null` mostra mensagem + ação "tentar novamente"
///   • lista vazia mostra empty state
class CnhhjSearchablePicker<T> extends StatelessWidget {
  const CnhhjSearchablePicker({
    super.key,
    required this.items,
    required this.label,
    required this.onSelected,
    this.selectedLabel,
    this.hint = 'Selecione',
    this.searchHint = 'Buscar...',
    this.loading = false,
    this.errorText,
    this.onRetry,
    this.enabled = true,
    this.icon,
  });

  final List<PickerItem<T>> items;
  final String label;
  final String? selectedLabel;
  final String hint;
  final String searchHint;
  final bool loading;
  final String? errorText;
  final VoidCallback? onRetry;
  final bool enabled;
  final IconData? icon;
  final ValueChanged<PickerItem<T>> onSelected;

  Future<void> _openSheet(BuildContext context) async {
    final PickerItem<T>? picked = await showModalBottomSheet<PickerItem<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _PickerSheet<T>(
        items: items,
        title: label,
        searchHint: searchHint,
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled && !loading && errorText == null
              ? () => _openSheet(context)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.surface
                  : AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.textPrimary.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 20, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    selectedLabel ?? hint,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: selectedLabel == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight: selectedLabel == null
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textPrimary,
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  errorText!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(
                    PhosphorIconsRegular.arrowsClockwise,
                    size: 14,
                  ),
                  label: Text(
                    'Tentar novamente',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.items,
    required this.title,
    required this.searchHint,
  });

  final List<PickerItem<T>> items;
  final String title;
  final String searchHint;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PickerItem<T>> get _filtered {
    if (_query.trim().isEmpty) return widget.items;
    final String q = _query.trim().toLowerCase();
    return widget.items
        .where((PickerItem<T> it) => it.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext ctx, ScrollController scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (String v) => setState(() => _query = v),
                autofocus: false,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            PhosphorIconsRegular.x,
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.primary.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            PhosphorIconsRegular.magnifyingGlass,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum resultado para "$_query"',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      itemBuilder: (BuildContext c, int i) {
                        final PickerItem<T> item = _filtered[i];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            child: Text(
                              item.label,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext c, int i) => Divider(
                        height: 1,
                        color: AppColors.textPrimary.withOpacity(0.08),
                      ),
                      itemCount: _filtered.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

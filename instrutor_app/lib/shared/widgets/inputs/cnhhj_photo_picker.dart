import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';

/// Campo para tirar/escolher foto. Usado em onboarding do instrutor:
/// foto do veículo (frente, trás), foto de perfil, CNH, certificado DETRAN.
///
/// Mostra um placeholder com ícone enquanto não há foto; quando há, exibe
/// thumbnail com opção de remover/trocar.
class CnhhjPhotoPicker extends StatefulWidget {
  const CnhhjPhotoPicker({
    super.key,
    this.label,
    this.hint = 'Toque para adicionar foto',
    this.exampleAsset,
    this.onChanged,
    this.initialFile,
    this.allowCamera = true,
    this.allowGallery = true,
  });

  final String? label;
  final String hint;

  /// Caminho de uma imagem em `assets/` que serve como exemplo (ex: "carro
  /// de frente 3/4"). Mostrada acima do placeholder quando definida.
  final String? exampleAsset;

  final ValueChanged<File?>? onChanged;
  final File? initialFile;
  final bool allowCamera;
  final bool allowGallery;

  @override
  State<CnhhjPhotoPicker> createState() => _CnhhjPhotoPickerState();
}

class _CnhhjPhotoPickerState extends State<CnhhjPhotoPicker> {
  File? _file;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _file = widget.initialFile;
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _file = File(picked.path));
    widget.onChanged?.call(_file);
  }

  void _remove() {
    setState(() => _file = null);
    widget.onChanged?.call(null);
  }

  Future<void> _showSourcePicker() async {
    if (!widget.allowCamera && !widget.allowGallery) return;
    if (widget.allowCamera && !widget.allowGallery) {
      await _pick(ImageSource.camera);
      return;
    }
    if (!widget.allowCamera && widget.allowGallery) {
      await _pick(ImageSource.gallery);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
          const SizedBox(height: 8),
        ],
        if (widget.exampleAsset != null) ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              widget.exampleAsset!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: AppColors.surfaceOverlay,
                child: const Center(
                  child: Icon(Icons.image_outlined, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _showSourcePicker,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: _file == null
                ? _Placeholder(hint: widget.hint)
                : Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_file!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: AppColors.textPrimary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _remove,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close,
                                color: AppColors.surface,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.add_a_photo_outlined,
          size: 36,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

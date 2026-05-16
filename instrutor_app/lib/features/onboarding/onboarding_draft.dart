import 'dart:convert';
import 'dart:io';

import '../../data/models/enums.dart';

/// Rascunho do cadastro do instrutor — vai sendo preenchido a cada
/// passo do wizard. No final é convertido em chamadas para
/// `InstructorRepository.upsert` e `InstructorRepository.updateProfile`.
class OnboardingDraft {
  const OnboardingDraft({
    // Step 1 — dados pessoais
    this.fullName,
    this.cpf,
    this.gender,
    this.birthDate,
    this.phone,
    // Step 2 — tipo + categorias
    this.vehicleType,
    this.categories = const <VehicleCategory>[],
    // Step 3 — dados do veículo
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleTransmission,
    this.vehiclePlate,
    // Steps 4/5/6/7 — fotos e documentos
    this.vehiclePhotoFront,
    this.vehiclePhotoBack,
    this.profilePhoto,
    this.cnhPhoto,
    this.detranCertificate,
  });

  final String? fullName;
  final String? cpf;
  final Gender? gender;
  final DateTime? birthDate;
  final String? phone;

  final VehicleType? vehicleType;
  final List<VehicleCategory> categories;

  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final Transmission? vehicleTransmission;
  final String? vehiclePlate;

  final File? vehiclePhotoFront;
  final File? vehiclePhotoBack;
  final File? profilePhoto;
  final File? cnhPhoto;
  final File? detranCertificate;

  /// Serializa apenas os campos *textuais* — fotos (`File`) não persistem
  /// entre kills do app porque o SO pode limpar o cache. O usuário precisa
  /// re-tirar fotos se voltar mais tarde, mas não perde nome/CPF/veículo.
  String toJsonString() => jsonEncode(<String, dynamic>{
        'fullName': fullName,
        'cpf': cpf,
        'gender': gender?.toJson(),
        'birthDate': birthDate?.toIso8601String(),
        'phone': phone,
        'vehicleType': vehicleType?.toJson(),
        'categories':
            categories.map((VehicleCategory c) => c.toJson()).toList(),
        'vehicleBrand': vehicleBrand,
        'vehicleModel': vehicleModel,
        'vehicleYear': vehicleYear,
        'vehicleTransmission': vehicleTransmission?.toJson(),
        'vehiclePlate': vehiclePlate,
      });

  static OnboardingDraft? tryFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      return OnboardingDraft(
        fullName: j['fullName'] as String?,
        cpf: j['cpf'] as String?,
        gender:
            j['gender'] == null ? null : Gender.fromJson(j['gender'] as String),
        birthDate: j['birthDate'] == null
            ? null
            : DateTime.tryParse(j['birthDate'] as String),
        phone: j['phone'] as String?,
        vehicleType: j['vehicleType'] == null
            ? null
            : VehicleType.fromJson(j['vehicleType'] as String),
        categories: ((j['categories'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic c) => VehicleCategory.fromJson(c as String))
            .toList(growable: false),
        vehicleBrand: j['vehicleBrand'] as String?,
        vehicleModel: j['vehicleModel'] as String?,
        vehicleYear: (j['vehicleYear'] as num?)?.toInt(),
        vehicleTransmission: j['vehicleTransmission'] == null
            ? null
            : Transmission.fromJson(j['vehicleTransmission'] as String),
        vehiclePlate: j['vehiclePlate'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  OnboardingDraft copyWith({
    String? fullName,
    String? cpf,
    Gender? gender,
    DateTime? birthDate,
    String? phone,
    VehicleType? vehicleType,
    List<VehicleCategory>? categories,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    Transmission? vehicleTransmission,
    String? vehiclePlate,
    File? vehiclePhotoFront,
    File? vehiclePhotoBack,
    File? profilePhoto,
    File? cnhPhoto,
    File? detranCertificate,
  }) {
    return OnboardingDraft(
      fullName: fullName ?? this.fullName,
      cpf: cpf ?? this.cpf,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      categories: categories ?? this.categories,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleTransmission: vehicleTransmission ?? this.vehicleTransmission,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehiclePhotoFront: vehiclePhotoFront ?? this.vehiclePhotoFront,
      vehiclePhotoBack: vehiclePhotoBack ?? this.vehiclePhotoBack,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      cnhPhoto: cnhPhoto ?? this.cnhPhoto,
      detranCertificate: detranCertificate ?? this.detranCertificate,
    );
  }
}

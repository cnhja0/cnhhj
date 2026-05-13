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

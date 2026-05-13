import '../models/instructor.dart';
import '../models/profile.dart';

/// Atualização parcial dos dados do instrutor durante o wizard de cadastro
/// e edição posterior. Todos os campos opcionais — só os preenchidos são
/// atualizados.
class InstructorUpdate {
  const InstructorUpdate({
    this.bio,
    this.state,
    this.city,
    this.neighborhood,
    this.serviceRadiusKm,
    this.cnhPhotoUrl,
    this.detranCertificateUrl,
    this.vehicleType,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleTransmission,
    this.vehiclePlate,
    this.vehiclePhotoFrontUrl,
    this.vehiclePhotoBackUrl,
    this.categories,
    this.pricePerClass,
    this.isActive,
  });

  final String? bio;
  final String? state;
  final String? city;
  final String? neighborhood;
  final int? serviceRadiusKm;
  final String? cnhPhotoUrl;
  final String? detranCertificateUrl;
  final dynamic vehicleType;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final dynamic vehicleTransmission;
  final String? vehiclePlate;
  final String? vehiclePhotoFrontUrl;
  final String? vehiclePhotoBackUrl;
  final List<dynamic>? categories;
  final double? pricePerClass;
  final bool? isActive;
}

abstract class InstructorRepository {
  /// Carrega o instrutor pelo id (mesmo id do profile).
  /// Retorna null se ainda não houver registro em `instructors` (durante o
  /// wizard de cadastro, o profile existe mas o instructor é criado no fim).
  Future<Instructor?> getById(String id);

  /// Atualiza ou cria o registro de instrutor. Retorna a versão atualizada.
  Future<Instructor> upsert(String id, InstructorUpdate patch);

  /// Atualiza apenas o profile (nome, telefone, avatar — fora dos campos
  /// específicos de instructor).
  Future<Profile> updateProfile(
    String id, {
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  /// Liga/desliga a aceitação de novas aulas (toggle "Ligado/Desligado").
  Future<void> setActive(String id, {required bool active});
}

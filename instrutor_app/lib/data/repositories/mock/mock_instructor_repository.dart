import '../../models/enums.dart';
import '../../models/instructor.dart';
import '../../models/profile.dart';
import '../instructor_repository.dart';
import '_seed.dart';

class MockInstructorRepository implements InstructorRepository {
  @override
  Future<Instructor?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockState.instance.instructors[id];
  }

  @override
  Future<Instructor> upsert(String id, InstructorUpdate patch) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final DateTime now = DateTime.now();
    final Instructor? existing = MockState.instance.instructors[id];

    final Instructor updated = (existing ??
            Instructor(id: id, createdAt: now, updatedAt: now))
        .copyWith(
      bio: patch.bio,
      state: patch.state,
      city: patch.city,
      neighborhood: patch.neighborhood,
      serviceRadiusKm: patch.serviceRadiusKm,
      cnhPhotoUrl: patch.cnhPhotoUrl,
      detranCertificateUrl: patch.detranCertificateUrl,
      vehicleType: patch.vehicleType,
      vehicleBrand: patch.vehicleBrand,
      vehicleModel: patch.vehicleModel,
      vehicleYear: patch.vehicleYear,
      vehicleTransmission: patch.vehicleTransmission,
      vehiclePlate: patch.vehiclePlate,
      vehiclePhotoFrontUrl: patch.vehiclePhotoFrontUrl,
      vehiclePhotoBackUrl: patch.vehiclePhotoBackUrl,
      categories: patch.categories,
      pricePerClass: patch.pricePerClass,
      isActive: patch.isActive,
      updatedAt: now,
    );

    MockState.instance.instructors[id] = updated;
    return updated;
  }

  @override
  Future<Profile> updateProfile(
    String id, {
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    Gender? gender,
    String? phone,
    String? avatarUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final Profile? current = MockState.instance.profiles[id];
    if (current == null) {
      throw StateError('Profile não encontrado: $id');
    }
    final Profile updated = current.copyWith(
      fullName: fullName,
      cpf: cpf,
      birthDate: birthDate,
      gender: gender,
      phone: phone,
      avatarUrl: avatarUrl,
      updatedAt: DateTime.now(),
    );
    MockState.instance.profiles[id] = updated;
    return updated;
  }

  @override
  Future<void> setActive(String id, {required bool active}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final Instructor? cur = MockState.instance.instructors[id];
    if (cur == null) return;
    MockState.instance.instructors[id] =
        cur.copyWith(isActive: active, updatedAt: DateTime.now());
  }
}

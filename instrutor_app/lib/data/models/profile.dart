import 'enums.dart';

/// Dados de identidade comuns a instrutores e alunos.
/// Espelha a tabela `profiles` do PostgreSQL.
class Profile {
  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    this.cpf,
    this.birthDate,
    this.gender,
    this.phone,
    this.avatarUrl,
    this.approvalStatus = ApprovalStatus.approved,
    this.approvedAt,
    this.rejectedReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final UserRole role;
  final String fullName;
  final String? cpf;
  final DateTime? birthDate;
  final Gender? gender;
  final String? phone;
  final String? avatarUrl;
  final ApprovalStatus approvalStatus;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile copyWith({
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    Gender? gender,
    String? phone,
    String? avatarUrl,
    ApprovalStatus? approvalStatus,
    DateTime? approvedAt,
    String? rejectedReason,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      role: role,
      fullName: fullName ?? this.fullName,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: UserRole.fromJson(json['role'] as String),
      fullName: json['full_name'] as String,
      cpf: json['cpf'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      gender: json['gender'] == null
          ? null
          : Gender.fromJson(json['gender'] as String),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      approvalStatus:
          ApprovalStatus.fromJson(json['approval_status'] as String),
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
      rejectedReason: json['rejected_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'role': role.toJson(),
        'full_name': fullName,
        'cpf': cpf,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'gender': gender?.toJson(),
        'phone': phone,
        'avatar_url': avatarUrl,
        'approval_status': approvalStatus.toJson(),
        'approved_at': approvedAt?.toIso8601String(),
        'rejected_reason': rejectedReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

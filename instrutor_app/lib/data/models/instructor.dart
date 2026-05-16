import 'enums.dart';

/// Dados específicos do instrutor. Espelha a tabela `instructors`.
class Instructor {
  const Instructor({
    required this.id,
    this.bio,
    this.state,
    this.city,
    this.neighborhood,
    this.serviceRadiusKm = 10,
    this.cnhPhotoUrl,
    this.detranCertificateUrl,
    this.vehicleType = VehicleType.carro,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleTransmission = Transmission.manual,
    this.vehiclePlate,
    this.vehiclePhotoFrontUrl,
    this.vehiclePhotoBackUrl,
    this.vehicleLastChangedAt,
    this.categories = const <VehicleCategory>[],
    this.pricePerClass,
    this.isActive = true,
    this.averageRating = 0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? bio;

  // Localização
  final String? state;
  final String? city;
  final String? neighborhood;
  final int serviceRadiusKm;

  // Documentos
  final String? cnhPhotoUrl;
  final String? detranCertificateUrl;

  // Veículo
  final VehicleType vehicleType;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final Transmission vehicleTransmission;
  final String? vehiclePlate;
  final String? vehiclePhotoFrontUrl;
  final String? vehiclePhotoBackUrl;

  /// Marca quando o instrutor alterou os dados do veículo pela última vez.
  /// Usado para aplicar cooldown de 7 dias e impedir trocas frequentes
  /// (anti-fraude). Null = nunca foi alterado pós-cadastro.
  final DateTime? vehicleLastChangedAt;

  // Comercial
  final List<VehicleCategory> categories;
  final double? pricePerClass;

  // Estado
  final bool isActive;

  // Reputação
  final double averageRating;
  final int totalReviews;

  final DateTime createdAt;
  final DateTime updatedAt;

  Instructor copyWith({
    String? bio,
    String? state,
    String? city,
    String? neighborhood,
    int? serviceRadiusKm,
    String? cnhPhotoUrl,
    String? detranCertificateUrl,
    VehicleType? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    Transmission? vehicleTransmission,
    String? vehiclePlate,
    String? vehiclePhotoFrontUrl,
    String? vehiclePhotoBackUrl,
    DateTime? vehicleLastChangedAt,
    List<VehicleCategory>? categories,
    double? pricePerClass,
    bool? isActive,
    double? averageRating,
    int? totalReviews,
    DateTime? updatedAt,
  }) {
    return Instructor(
      id: id,
      bio: bio ?? this.bio,
      state: state ?? this.state,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      cnhPhotoUrl: cnhPhotoUrl ?? this.cnhPhotoUrl,
      detranCertificateUrl: detranCertificateUrl ?? this.detranCertificateUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleTransmission: vehicleTransmission ?? this.vehicleTransmission,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehiclePhotoFrontUrl:
          vehiclePhotoFrontUrl ?? this.vehiclePhotoFrontUrl,
      vehiclePhotoBackUrl: vehiclePhotoBackUrl ?? this.vehiclePhotoBackUrl,
      vehicleLastChangedAt:
          vehicleLastChangedAt ?? this.vehicleLastChangedAt,
      categories: categories ?? this.categories,
      pricePerClass: pricePerClass ?? this.pricePerClass,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as String,
      bio: json['bio'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toInt() ?? 10,
      cnhPhotoUrl: json['cnh_photo_url'] as String?,
      detranCertificateUrl: json['detran_certificate_url'] as String?,
      vehicleType: VehicleType.fromJson(json['vehicle_type'] as String),
      vehicleBrand: json['vehicle_brand'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleYear: (json['vehicle_year'] as num?)?.toInt(),
      vehicleTransmission:
          Transmission.fromJson(json['vehicle_transmission'] as String),
      vehiclePlate: json['vehicle_plate'] as String?,
      vehiclePhotoFrontUrl: json['vehicle_photo_front_url'] as String?,
      vehiclePhotoBackUrl: json['vehicle_photo_back_url'] as String?,
      vehicleLastChangedAt: json['vehicle_last_changed_at'] == null
          ? null
          : DateTime.parse(json['vehicle_last_changed_at'] as String),
      categories: ((json['categories'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic c) => VehicleCategory.fromJson(c as String))
          .toList(growable: false),
      pricePerClass: (json['price_per_class'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'bio': bio,
        'state': state,
        'city': city,
        'neighborhood': neighborhood,
        'service_radius_km': serviceRadiusKm,
        'cnh_photo_url': cnhPhotoUrl,
        'detran_certificate_url': detranCertificateUrl,
        'vehicle_type': vehicleType.toJson(),
        'vehicle_brand': vehicleBrand,
        'vehicle_model': vehicleModel,
        'vehicle_year': vehicleYear,
        'vehicle_transmission': vehicleTransmission.toJson(),
        'vehicle_plate': vehiclePlate,
        'vehicle_photo_front_url': vehiclePhotoFrontUrl,
        'vehicle_photo_back_url': vehiclePhotoBackUrl,
        'vehicle_last_changed_at': vehicleLastChangedAt?.toIso8601String(),
        'categories':
            categories.map((VehicleCategory c) => c.toJson()).toList(),
        'price_per_class': pricePerClass,
        'is_active': isActive,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

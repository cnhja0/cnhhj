import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'steps/step_1_personal_data.dart';
import 'steps/step_2_vehicle_type.dart';
import 'steps/step_3_vehicle_details.dart';
import 'steps/step_4_vehicle_photo_front.dart';
import 'steps/step_5_vehicle_photo_back.dart';
import 'steps/step_6_profile_photo.dart';
import 'steps/step_7_documents.dart';

/// Roteador dos 7 passos do wizard. Recebe o número do passo (1..7) e
/// renderiza o widget correspondente. As rotas individuais em `app_router`
/// usam esta classe.
class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (step) {
      1 => const Step1PersonalData(),
      2 => const Step2VehicleType(),
      3 => const Step3VehicleDetails(),
      4 => const Step4VehiclePhotoFront(),
      5 => const Step5VehiclePhotoBack(),
      6 => const Step6ProfilePhoto(),
      7 => const Step7Documents(),
      _ => const Scaffold(body: Center(child: Text('Passo inválido'))),
    };
  }
}

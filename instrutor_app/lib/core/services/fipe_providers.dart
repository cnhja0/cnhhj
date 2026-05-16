import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import 'fipe_service.dart';

/// Provider único do client FIPE — `keepAlive` para reusar a `http.Client`
/// entre invocações (TCP keep-alive, sem reabrir socket toda hora).
final Provider<FipeService> fipeServiceProvider = Provider<FipeService>((Ref ref) {
  final FipeService svc = FipeService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Marcas para um tipo de veículo. AutoDispose com keepAlive — uma vez
/// carregadas, o resultado permanece em cache até o usuário sair da aba.
/// A API FIPE é estável (marcas mudam raramente), então não há ttl.
final AutoDisposeFutureProviderFamily<List<FipeItem>, VehicleType>
    fipeBrandsProvider =
    FutureProvider.autoDispose.family<List<FipeItem>, VehicleType>(
  (AutoDisposeFutureProviderRef<List<FipeItem>> ref, VehicleType type) async {
    ref.keepAlive();
    final FipeService svc = ref.read(fipeServiceProvider);
    return svc.brands(type);
  },
);

/// Modelos para um par (tipo, marca). Mesmo padrão keepAlive: depois de
/// buscar a lista para "Volkswagen carro", se o usuário voltar a essa
/// marca não há nova chamada de rede.
class FipeModelsKey {
  const FipeModelsKey({required this.type, required this.brandCode});
  final VehicleType type;
  final String brandCode;

  @override
  bool operator ==(Object other) =>
      other is FipeModelsKey &&
      other.type == type &&
      other.brandCode == brandCode;

  @override
  int get hashCode => Object.hash(type, brandCode);
}

final AutoDisposeFutureProviderFamily<List<FipeItem>, FipeModelsKey>
    fipeModelsProvider =
    FutureProvider.autoDispose.family<List<FipeItem>, FipeModelsKey>(
  (AutoDisposeFutureProviderRef<List<FipeItem>> ref, FipeModelsKey key) async {
    ref.keepAlive();
    final FipeService svc = ref.read(fipeServiceProvider);
    return svc.models(key.type, key.brandCode);
  },
);

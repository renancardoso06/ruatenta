import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Obtém a posição do aparelho uma única vez, sob demanda.
/// Não mantém stream de GPS aberto: evita consumo de bateria e vazamento de
/// memória por assinatura esquecida.
class LocalizacaoService {
  /// Retorna null se o serviço estiver desligado, a permissão for negada ou a
  /// leitura demorar demais. O chamador mostra a mensagem apropriada.
  Future<LatLng?> posicaoAtual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocalizacaoService {
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

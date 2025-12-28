import 'package:geolocator/geolocator.dart';

class LocationService {
  // Verificar permisos de ubicación
  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Verificar si el servicio de ubicación está habilitado
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Verificar permisos
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking location permission: $e');
      // En caso de error, devolver true para no bloquear el flujo
      return true;
    }
  }

  // Obtener ubicación actual
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Formatear ubicación como string
  String formatLocation(Position? position) {
    if (position == null) return 'N/A';
    return '${position.latitude} ${position.longitude}';
  }

  // Calcular distancia entre dos puntos
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Verificar si está dentro del rango permitido
  bool isWithinRange(
    Position currentPosition,
    double targetLatitude,
    double targetLongitude,
    double maxDistanceInMeters,
  ) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    
    return distance <= maxDistanceInMeters;
  }
}

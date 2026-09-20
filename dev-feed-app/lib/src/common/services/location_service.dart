import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

/// Na Web, localização no boot costuma falhar (sem gesto do usuário).
/// Use [skipBootLocationCheck] em [initDependencies].
bool get skipBootLocationCheck => kIsWeb;

class LocationPosition {
  final double latitude;
  final double longitude;

  LocationPosition({required this.latitude, required this.longitude});
}

abstract interface class LocationService {
  bool get isEnabled;

  Future<void> checkLocation();
  Future<LocationPosition?> getCurrentLocation();
}

class LocationServiceImpl implements LocationService {
  final Location _location = Location();

  bool _isEnabled = false;

  @override
  bool get isEnabled => _isEnabled;

  bool _isPermissionGranted(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited;
  }

  Future<bool> _ensurePermission() async {
    var permission = await _location.hasPermission();
    if (_isPermissionGranted(permission)) return true;

    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      return _isPermissionGranted(permission);
    }

    return false;
  }

  @override
  Future<void> checkLocation() async {
    try {
      if (kIsWeb) {
        // Permissão real na Web: no gesto de criar post (getCurrentLocation).
        _isEnabled = false;
        debugPrint('Location: Web boot skip (deferred to user gesture)');
        return;
      }

      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _isEnabled = false;
          debugPrint('Location service disabled');
          return;
        }
      }

      if (!await _ensurePermission()) {
        _isEnabled = false;
        debugPrint('Location permission denied');
        return;
      }

      _isEnabled = true;
      debugPrint('Location enabled? true');
    } catch (error) {
      _isEnabled = false;
      debugPrint('LocationService checkLocation: $error');
    }
  }

  Future<LocationPosition?> _readLocationData() async {
    final data = await _location.getLocation();
    if (data.latitude == null || data.longitude == null) return null;

    return LocationPosition(
      latitude: data.latitude!,
      longitude: data.longitude!,
    );
  }

  @override
  Future<LocationPosition?> getCurrentLocation() async {
    try {
      if (kIsWeb) {
        if (!await _ensurePermission()) {
          _isEnabled = false;
          return null;
        }
        _isEnabled = true;
        return await _readLocationData();
      }

      if (!_isEnabled) {
        await checkLocation();
        if (!_isEnabled) return null;
      }

      return await _readLocationData();
    } catch (error) {
      _isEnabled = false;
      debugPrint('LocationService getCurrentLocation: $error');
      return null;
    }
  }
}

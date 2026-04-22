import 'package:disaster_response_mobile/core/services/map_service.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final String city;
  final String riskLevel;
  final String alertTitle;
  final String alertDescription;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.city,
    required this.riskLevel,
    required this.alertTitle,
    required this.alertDescription,
  });
}

class WeatherProvider with ChangeNotifier {
  final Dio _dio = Dio();
  final MapService _mapService = MapService();

  WeatherData? _currentWeather;
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WeatherProvider() {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await _mapService.getCurrentLocation();
      if (position == null) {
        _error = 'Location not available';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Get Geocoding data
      String city = 'Unknown Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          city =
              placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              'Unknown';
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      // 2. Get Weather data from Open-Meteo
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code';

      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data['current'];
        final weatherCode = data['weather_code'] as int;
        final windSpeed = (data['wind_speed_10m'] as num).toDouble();
        final alert = _generateAlert(weatherCode, windSpeed);

        _currentWeather = WeatherData(
          temperature: (data['temperature_2m'] as num).toDouble(),
          condition: _mapWeatherCode(weatherCode),
          humidity: data['relative_humidity_2m'] as int,
          windSpeed: windSpeed,
          city: city,
          riskLevel: _calculateRiskLevel(weatherCode, windSpeed),
          alertTitle: alert['title']!,
          alertDescription: alert['description']!,
        );
      } else {
        _error = 'Failed to fetch weather';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapWeatherCode(int code) {
    if (code == 0) return 'Clear';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  String _calculateRiskLevel(int code, double windSpeed) {
    if (code >= 95 || windSpeed > 50) return 'High';
    if (code >= 80 || windSpeed > 30) return 'Moderate';
    return 'Low';
  }

  Map<String, String> _generateAlert(int code, double windSpeed) {
    if (code >= 95) {
      return {
        'title': 'Extreme Weather Alert',
        'description': 'Thunderstorm detected. Seek shelter immediately.',
      };
    }
    if (code >= 80 || code == 65) {
      return {
        'title': 'Flood Risk Alert',
        'description': 'Heavy rainfall detected. High risk of flash flooding.',
      };
    }
    if (windSpeed > 40) {
      return {
        'title': 'High Wind Advisory',
        'description': 'Strong winds detected. Secure loose outdoor items.',
      };
    }
    if (code >= 71 && code <= 77) {
      return {
        'title': 'Blizzard Warning',
        'description': 'Snowfall detected. Avoid travel if possible.',
      } ;
    }
     if (code >= 45 && code <= 48) {
      return {
        'title': 'Visibility Alert',
        'description': 'Dense fog detected. Drive with extra caution.',
      };
    }
    return {
      'title': 'All Clear',
      'description': 'No active weather threats. Stay safe and informed.',
    };
  }
}

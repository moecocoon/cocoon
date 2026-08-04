import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String condition;
  final String description;
  final String cityName;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.cityName,
  });

  String get temperatureText =>
      '${temperature.round()}℃';

  String get weatherLabel {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '晴れ';
      case 'clouds':
        return 'くもり';
      case 'rain':
      case 'drizzle':
        return '雨';
      case 'thunderstorm':
        return '雷雨';
      case 'snow':
        return '雪';
      case 'mist':
      case 'fog':
      case 'haze':
        return '霧';
      default:
        return description;
    }
  }

  String get weatherEmoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}

class WeatherService {
  final String apiKey;

  const WeatherService({
    required this.apiKey,
  });

  Future<WeatherData> getCurrentWeather() async {
    final position = await _determinePosition();

    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
        'lang': 'ja',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        '天気の取得に失敗しました：${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body)
        as Map<String, dynamic>;

    final main =
        json['main'] as Map<String, dynamic>?;

    final weatherList =
        json['weather'] as List<dynamic>?;

    if (main == null ||
        weatherList == null ||
        weatherList.isEmpty) {
      throw Exception('天気データの形式が正しくありません。');
    }

    final weather =
        weatherList.first as Map<String, dynamic>;

    return WeatherData(
      temperature:
          (main['temp'] as num).toDouble(),
      condition:
          weather['main']?.toString() ?? '',
      description:
          weather['description']?.toString() ?? '',
      cityName:
          json['name']?.toString() ?? '現在地',
    );
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('端末の位置情報がオフになっています。');
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('位置情報の利用が許可されませんでした。');
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        '位置情報が拒否されています。端末の設定から許可してください。',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    );
  }
}
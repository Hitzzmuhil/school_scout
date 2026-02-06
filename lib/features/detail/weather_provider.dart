import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/weather.dart';
import '../../services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherProvider = FutureProvider.autoDispose.family<WeatherForecast, ({double lat, double lng})>((ref, location) async {
  final service = ref.watch(weatherServiceProvider);
  return service.getWeather(location.lat, location.lng);
});

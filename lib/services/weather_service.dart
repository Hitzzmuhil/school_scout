import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  final String? _apiKey = dotenv.env['OPENWEATHER_API_KEY'];

  Future<WeatherForecast> getWeather(double lat, double lng) async {
    if (_apiKey == null) {
      print("NO API KEY!");
      throw Exception('OpenWeather API Key not configured');
    }

    try {
      print("Getting Current Weather...");
      String urlString = 'https://api.openweathermap.org/data/2.5/weather?lat=' + lat.toString() + '&lon=' + lng.toString() + '&units=imperial&appid=' + _apiKey!;
      print(urlString);

      final currentRes = await http.get(Uri.parse(urlString));
      
      if (currentRes.statusCode != 200) {
        print("Error code: " + currentRes.statusCode.toString());
        throw Exception('Failed to load current weather');
      }
      
      var currentData = json.decode(currentRes.body);
      var current = Weather.fromJson(currentData);

      print("Getting Forecast...");
      String forecastUrlString = 'https://api.openweathermap.org/data/2.5/forecast?lat=' + lat.toString() + '&lon=' + lng.toString() + '&units=imperial&appid=' + _apiKey!;
      
      final forecastRes = await http.get(Uri.parse(forecastUrlString));
      if (forecastRes.statusCode != 200) {
         print("Forecast failed, returning current only");
         return WeatherForecast(current: current, daily: []); 
      }
      
      var forecastData = json.decode(forecastRes.body);
      var list = forecastData['list'] as List;
      
      Map<String, DailyWeather> dailyMap = {};
      
      for (var item in list) {
         int dt = item['dt'];
         var date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
         String dayKey = date.year.toString() + '-' + date.month.toString() + '-' + date.day.toString();
         
         if (!dailyMap.containsKey(dayKey) || date.hour == 12) {
             dailyMap[dayKey] = DailyWeather.fromJson(item);
         }
      }

      print("Forecast processing done");
      return WeatherForecast(current: current, daily: dailyMap.values.take(7).toList());

    } catch (e) {
      print("Something went wrong in weather service: " + e.toString());
      throw Exception('Weather Error: $e');
    }
  }
}

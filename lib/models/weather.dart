class Weather {
  double temp;
  String description;
  String icon;
  int dt;

  Weather({
    required this.temp,
    required this.description,
    required this.icon,
    required this.dt,
  });

  static Weather fromJson(Map<String, dynamic> json) {
    // print("parsing weather data...");
    var list = json['weather'] as List;
    var weatherItem = list[0]; // assuming there is one

    // checking for temp in different places because api is confusing
    double temperature = 0.0;
    if (json['main'] != null) {
      temperature = (json['main']['temp'] as num).toDouble();
    } else if (json['temp'] != null) {
      temperature = (json['temp'] as num).toDouble();
    }

    return Weather(
      temp: temperature,
      description: weatherItem['description'],
      icon: weatherItem['icon'],
      dt: json['dt'],
    );
  }
}

class DailyWeather {
  double minTemp;
  double maxTemp;
  String description;
  String icon;
  int dt;

  DailyWeather({
    required this.minTemp,
    required this.maxTemp,
    required this.description,
    required this.icon,
    required this.dt,
  });

  static DailyWeather fromJson(Map<String, dynamic> json) {
    var weatherList = json['weather'] as List;
    var weatherObj = weatherList[0];
    
    var tempObj = json['temp'];
    
    return DailyWeather(
      minTemp: (tempObj['min'] as num).toDouble(),
      maxTemp: (tempObj['max'] as num).toDouble(),
      description: weatherObj['description'],
      icon: weatherObj['icon'],
      dt: json['dt'],
    );
  }
}

class WeatherForecast {
  Weather current;
  List<DailyWeather> daily;

  WeatherForecast({required this.current, required this.daily});
}

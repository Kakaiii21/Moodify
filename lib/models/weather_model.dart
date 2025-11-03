class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final int humidity;
  final double windSpeed;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.humidity,
    required this.windSpeed,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final weatherData = json['weather'][0];
    final main = weatherData['main']?.toString().toLowerCase() ?? '';
    final desc = weatherData['description']?.toString().toLowerCase() ?? '';

    // Prefer description if available
    final condition = desc.isNotEmpty ? desc : main;

    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: condition,
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }
}

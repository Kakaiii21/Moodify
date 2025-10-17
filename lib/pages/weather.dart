import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:moodify/models/weather_model.dart';
import 'package:moodify/services/weather_services.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('10e8bf0cef40ac94d16f23393a11bec6');
  Weather? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      String cityName = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Unable to fetch weather data";
      });
      print(e);
    }
  }

  // choose Lottie animation based on weather condition
  String _getWeatherAnimation(String mainCondition) {
    if (mainCondition.toLowerCase().contains("cloud")) {
      return 'https://assets10.lottiefiles.com/packages/lf20_jmBauI.json';
    } else if (mainCondition.toLowerCase().contains("rain")) {
      return 'https://assets10.lottiefiles.com/packages/lf20_rpC1Rd.json';
    } else if (mainCondition.toLowerCase().contains("clear")) {
      return 'https://assets10.lottiefiles.com/packages/lf20_xRmNN8.json';
    } else if (mainCondition.toLowerCase().contains("snow")) {
      return 'https://assets10.lottiefiles.com/packages/lf20_UJNc2t.json';
    } else {
      return 'https://assets10.lottiefiles.com/packages/lf20_w51pcehl.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.inversePrimary,
                )
              : _error != null
              ? Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 18,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🏙 City Name
                    Text(
                      _weather?.cityName ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ☀️ Weather Condition
                    Text(
                      _weather?.mainCondition ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🌤 Lottie animation
                    if (_weather != null)
                      Lottie.network(
                        _getWeatherAnimation(
                          _weather?.mainCondition ?? 'Clear',
                        ),
                        height: 180,
                        width: 180,
                      ),

                    const SizedBox(height: 20),

                    // 🌡 Temperature
                    Text(
                      '${_weather?.temperature.round()}°C',
                      style: GoogleFonts.poppins(
                        fontSize: 60,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 💧 Humidity & 🌬 Wind Speed
                    if (_weather != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 💧 Humidity
                          Column(
                            children: [
                              const Icon(
                                Icons.water_drop,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                              Text(
                                '${_weather!.humidity}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary,
                                ),
                              ),
                              Text(
                                "Humidity",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 50),
                          // 🌬 Wind Speed
                          Column(
                            children: [
                              const Icon(
                                Icons.air,
                                color: Colors.lightBlueAccent,
                                size: 28,
                              ),
                              Text(
                                '${_weather!.windSpeed} m/s',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary,
                                ),
                              ),
                              Text(
                                "Wind",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

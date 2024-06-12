import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'alarm_setting_page.dart';
import '../main.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _nextAlarm = ' Fetching...';
  String _recommendedTimes = ' Calculating...';
  List<HealthDataPoint> _sleepData = [];
  Health health = Health();

  @override
  void initState() {
    super.initState();
    _fetchSleepData();
  }

  Future<void> _fetchSleepData() async {
    try {
      // Fetch next alarm from the server
      final alarmResponse = await http.get(Uri.parse('http://127.0.0.1:8080/api/alarm/next'));
      if (alarmResponse.statusCode == 200) {
        final alarmData = json.decode(alarmResponse.body);
        setState(() {
          _nextAlarm = ' ~ ${alarmData['nextAlarmTime']}';
          _recommendedTimes = (alarmData['recommendedTimes'] as List).join(' , ');
        });
      } else {
        print('Failed to fetch alarm with status code: ${alarmResponse.statusCode}');
        print('Response body: ${alarmResponse.body}');
        setState(() {
          _nextAlarm = 'Error fetching alarm';
        });
      }

      // Fetch sleep data from the server
      final sleepResponse = await http.get(Uri.parse('http://127.0.0.1:8080/api/sleep/data'));
      if (sleepResponse.statusCode == 200) {
        final sleepDataList = json.decode(sleepResponse.body) as List;
        List<HealthDataPoint> healthData = sleepDataList.map((item) {
          return HealthDataPoint.fromJson(item);
        }).toList();

        setState(() {
          _sleepData = healthData;
        });
      } else {
        print('Failed to fetch sleep data with status code: ${sleepResponse.statusCode}');
        print('Response body: ${sleepResponse.body}');
        setState(() {
          _useFakeSleepData();
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _nextAlarm = 'Error: $e';
        _useFakeSleepData();
      });
    }
  }

  void _useFakeSleepData() {
    _sleepData = [
      HealthDataPoint.fromJson({
        'typeString': 'SLEEP_ASLEEP',
        'value': 480,
        'unit': 'minutes',
        'dateFrom': DateTime.now().subtract(Duration(hours: 8)).toIso8601String(),
        'dateTo': DateTime.now().toIso8601String(),
      }),
      HealthDataPoint.fromJson({
        'typeString': 'SLEEP_AWAKE',
        'value': 60,
        'unit': 'minutes',
        'dateFrom': DateTime.now().subtract(Duration(hours: 9)).toIso8601String(),
        'dateTo': DateTime.now().subtract(Duration(hours: 8)).toIso8601String(),
      }),
      HealthDataPoint.fromJson({
        'typeString': 'SLEEP_IN_BED',
        'value': 540,
        'unit': 'minutes',
        'dateFrom': DateTime.now().subtract(Duration(hours: 9)).toIso8601String(),
        'dateTo': DateTime.now().toIso8601String(),
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: GradientBackground(
        child: ListView(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlarmSettingPage()),
                );
              },
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white10, // Box color
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ' Alarm for next morning :',
                      style: TextStyle(fontSize: 21, color: Colors.white),
                    ),
                    Row(children: [
                      Icon(Icons.alarm_outlined,
                          size: 60, color: Colors.white),
                      Text(
                        _nextAlarm,
                        style: TextStyle(fontSize: 50, color: Colors.white),
                      ),
                    ]),
                    Text(
                      ' Recommended sleep times :',
                      style: TextStyle(fontSize: 14, color: Colors.white24),
                    ),
                    Row(
                      children: [
                        Icon(Icons.night_shelter_outlined,
                            size: 20, color: Colors.white),
                        Text(
                          ' $_recommendedTimes',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white10, // Box color
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last sleep information',
                    style: TextStyle(fontSize: 21, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _buildSleepInfoCard(Icons.bedtime, 'Time in sleep', '9h 12m'),
                      _buildSleepInfoCard(Icons.wb_sunny, 'Wake up time', '10:32 AM'),
                      _buildSleepInfoCard(Icons.bed, 'Went to bed', '1:10 AM'),
                      _buildSleepInfoCard(Icons.timer, 'Fell asleep in', '15 min'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white24, // Box color
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
              Text(value, style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

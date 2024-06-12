import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSettingPage extends StatefulWidget {
  @override
  _AlarmSettingPageState createState() => _AlarmSettingPageState();
}

class _AlarmSettingPageState extends State<AlarmSettingPage> {
  TimeOfDay _alarmTime = TimeOfDay(hour: 0, minute: 0);
  bool _isLoading = false;
  bool _isInitialLoading = true;
  DateTime? _sleepStartTime;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
      if (_username != null) {
        _fetchCurrentAlarmTime();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 35, 36, 38),
      appBar: AppBar(title: Text('Set Alarm')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Alarm Time:',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            Text(
              '${_alarmTime.format(context)}',
              style: TextStyle(fontSize: 50, color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickTime,
              child: Text('Set Alarm'),
            ),
            SizedBox(height: 40),
            _sleepStartTime != null
                ? Text(
                    'You fell asleep at: ${TimeOfDay.fromDateTime(_sleepStartTime!).format(context)}',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  )
                : Text(
                    'Press the button when you go to bed',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _recordSleepAndSaveAlarm,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Good Night & Save Alarm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCurrentAlarmTime() async {
    try {
      final url = Uri.parse(
          'http://127.0.0.1:8080/api/alarm/next?username=$_username');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alarmTimeString = data['nextAlarmTime'];
        // final format = TimeOfDayFormat.H_colon_mm;

        setState(() {
          _alarmTime = TimeOfDay(
            hour: int.parse(alarmTimeString.split(':')[0]),
            minute: int.parse(alarmTimeString.split(':')[1].split(' ')[0]),
          );
          _isInitialLoading = false;
        });
      } else {
        print(
            'Failed to fetch current alarm time with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _recordSleepStartTime() {
    setState(() {
      _sleepStartTime = DateTime.now();
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    if (picked != null && picked != _alarmTime) {
      setState(() {
        _alarmTime = picked;
      });
    }
  }

  Future<void> _recordSleepAndSaveAlarm() async {
    if (_sleepStartTime == null) {
      _recordSleepStartTime();
    }

    setState(() {
      _isLoading = true;
    });

    DateTime alarmDateTime = _calculateOptimalWakeUpTime();

    final alarmTimeString =
        TimeOfDay.fromDateTime(alarmDateTime).format(context);
    final url = Uri.parse(
        'http://127.0.0.1:8080/api/alarm');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'alarmTime': alarmTimeString,
          'username': _username
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm time set successfully')),
        );

        _setAlarm(alarmDateTime);
      } else {
        print('Failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set alarm time')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //독창적 알고리즘 : 설정한 알람 시각 이전 30분 내에 수면 주기 끝부분(수면 시작 시간 + 1.5*n)이 존재하면, 그 시각으로 알람을 설정한다.
  DateTime _calculateOptimalWakeUpTime() {
    if (_sleepStartTime == null) {
      return DateTime.now();
    }

    DateTime targetAlarmDateTime = DateTime(
      _sleepStartTime!.year,
      _sleepStartTime!.month,
      _sleepStartTime!.day,
      _alarmTime.hour,
      _alarmTime.minute,
    );

    if (targetAlarmDateTime.isBefore(_sleepStartTime!)) {
      targetAlarmDateTime = targetAlarmDateTime.add(Duration(days: 1));
    }

    const sleepCycleDuration = Duration(minutes: 90);
    const sleepCycleRangeMin = 1; // Minimum cycles
    const sleepCycleRangeMax = 10; // Maximum cycles

    DateTime optimalAlarmTime = targetAlarmDateTime;
    Duration bestDifference = const Duration(hours: 24);

    for (int i = sleepCycleRangeMin; i <= sleepCycleRangeMax; i++) {
      Duration sleepCycleTotalDuration = sleepCycleDuration * i;
      DateTime possibleAlarmTime = _sleepStartTime!.add(sleepCycleTotalDuration);

      Duration difference = possibleAlarmTime.difference(targetAlarmDateTime).abs();
      if (difference < bestDifference && difference <= const Duration(minutes: 30)) {
        optimalAlarmTime = possibleAlarmTime;
        bestDifference = difference;
      }
    }

    return optimalAlarmTime;
  }

  void _setAlarm(DateTime dateTime) {
    final alarmSettings = AlarmSettings(
      id: 42,
      dateTime: dateTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      notificationTitle: 'Alarm',
      notificationBody: 'Time to wake up!',
      enableNotificationOnKill: true,
    );

    Alarm.set(alarmSettings: alarmSettings);
  }
}

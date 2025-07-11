import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rtm/connection/socket_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class Monthlychart extends StatefulWidget {
  const Monthlychart({super.key});

  @override
  State<Monthlychart> createState() => _MonthlychartState();
}

class _MonthlychartState extends State<Monthlychart> {
  final socketService = SocketService();
  final TextEditingController siteId = TextEditingController();
  final List<String> _items = [];
  String? _selectedItems;
  String? _email;

  // Data from API comm
  List<Map<String, List<FlSpot>>> chartGroups = [];
  Map<String, List<FlSpot>> chartDataMap = {}; // Save data for each device
  Map<double, String> deviceNames = {}; // for tooltip
  Map<double, String> indexToDate = {}; // for label X axis (date)

  // colour saver var
  Map<String, Color> deviceColors = {};

  void _handleWebsocketResponse(dynamic message) {
    if (!mounted) return;

    try {
      Map<String, dynamic> data = jsonDecode(message);
      if (data.containsKey("status") && data["status"] == "Stop") {
        if (data.containsKey("running_time_float")) {
          double timeFloat = double.tryParse(data["running_time_float"].toString()) ?? 0.0;
          String deviceName = data["device_name"] ?? "Unknown";
          
          setState(() {
            double index = chartDataMap.values.fold(0.0, (sum, list) => sum + list.length);

            // add data to group based on device_name
            chartDataMap.putIfAbsent(deviceName, () => []);
            chartDataMap[deviceName]!.add(FlSpot(index, timeFloat));

            deviceNames[index] = deviceName; // Save device_name for tooltip
          });
        }
      }
    } catch (e, stackTrace) {
      print("❌ Error parsing WebSocket response: $e");
      print(stackTrace);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEmail();
    print("📡 Initializing WebSocket...");

    bool isReconnecting = false;

    socketService.onStatusChange = (status) {
      print("🛜 WebSocket Status: $status");

      if (!mounted) return;

      if (status == "connected") {
        print("✅ Connected to WebSocket");
        isReconnecting = false;
      } else if (status == "disconnected" && !isReconnecting) {
        isReconnecting = true;
        print("⚠️ WebSocket Disconnected, retrying in 5 seconds...");

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && socketService.status != "connected") {
            print("🔄 Attempting to reconnect...");
            socketService.connect();
          }
          isReconnecting = false;
        });
      }
    };

    socketService.connect();
    socketService.onMessageReceived = (message) {
      print("🛜 WebSocket Message: $message"); // Debug log
      _handleWebsocketResponse(message);
    };
    print("✅ initState selesai");
  }

  Future<void> _loadEmail() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      _email = pref.getString('email') ?? 'null';
      print(_email);
    });
    _reader();
  }

  Future<void> _chartGetter() async {
    if (_email == null) {
      print("Email belum terload, coba lagi");
      return;
    }

    print("connecting API...");

    final res = await http.post(
      Uri.parse("https://rtm.envilife.co.id/api/data"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _email,
        'site_id': _selectedItems,
        'type': 'monthly_chart',
      }),
    );

    if (res.statusCode == 200) {
      if (res.body.trim() == 'null') {
        print("⚠️ Server mengembalikan null. Tidak ada data chart.");
        ScaffoldMessenger(
          child:
            Center(child:
            Text("Data is not available"),
            )
          );
        return;
      }

      final decoded = jsonDecode(res.body);

      if (decoded is! List) {
        print("❌ Format response tidak sesuai (bukan List): $decoded");
        return;
      }

      List<dynamic> data = decoded;
      print("✅ Data chart diterima: $data");

      // Collect all unique date from device
      Set<String> allDates = {};
      for (var device in data) {
        List<dynamic> entries = device['data'] ?? [];
        for (var entry in entries) {
          if (entry['month_start'] != null) {
            allDates.add(entry['month_start']);
          }
        }
      }

      // Arrange date Globaly
      List<String> sortedDates = allDates.toList()..sort();
      Map<String, double> dateToX = {};
      Map<double, String> newIndexToDate = {};

      for (int i = 0; i < sortedDates.length; i++) {
        dateToX[sortedDates[i]] = i.toDouble();
        newIndexToDate[i.toDouble()] = sortedDates[i];
      }

      Map<String, List<FlSpot>> newChartDataMap = {};
      Map<double, String> newDeviceNames = {};

      for (var device in data) {
        String deviceId = device['device_id'] ?? 'Unknown';
        List<dynamic> entries = device['data'] ?? [];
        newChartDataMap[deviceId] = [];

        for (var entry in entries) {
          String date = entry['month_start'];
          double total = double.tryParse(entry['total'].toString()) ?? 0.0;

          double? x = dateToX[date];
          if (x != null) {
            newChartDataMap[deviceId]!.add(FlSpot(x, total));
            newDeviceNames[x] = deviceId; // optional for tooltip
          }
        }

        // arrange FlSpot based on x
        newChartDataMap[deviceId]!.sort((a, b) => a.x.compareTo(b.x));
      }

      List<Map<String, List<FlSpot>>> groupedData = [];
        Map<String, List<FlSpot>> currentGroup = {};
        int counter = 0;

        newChartDataMap.forEach((key, value) {
          if (counter == 5) {
            groupedData.add(currentGroup);
            currentGroup = {};
            counter = 0;
          }
          currentGroup[key] = value;
          counter++;
        });

        if (currentGroup.isNotEmpty) {
          groupedData.add(currentGroup);
        }

        setState(() {
          chartGroups = groupedData;
          deviceNames = newDeviceNames;
          indexToDate = newIndexToDate;
        });
    } else {
      print("❌ Failed to get data Chart, code: ${res.statusCode}");
    }
  }

  Future<void> _reader() async {
    if (_email == null) {
      print("⚠️ Email hasnt been loaded, try again...");
      return;
    }

    print("📡 Connecting to API...");

    final response = await http.post(
      Uri.parse('https://rtm.envilife.co.id/api/data'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _email, 'type': 'site_id'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['site_id'] != null) {
        setState(() {
          _items.clear();
          _items.addAll(List<String>.from(data['site_id']));
        });
      }
    }
  }

  double getMinY() {
    if (chartDataMap.isEmpty) return 0;
    return chartDataMap.values.expand((list) => list).map((e) => e.y).reduce((a, b) => a < b ? a : b);
  }

  double getMaxY() {
    if (chartDataMap.isEmpty) return 6;
    return chartDataMap.values.expand((list) => list).map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }

  List<LineChartBarData> getChartBars() {
    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange];
    int index = 0;

    return chartDataMap.entries.map((entry) {
      Color lineColor = colors[index % colors.length]; // Warna unik per device
      index++;

      return LineChartBarData(
        spots: entry.value,
        isCurved: true,
        color: lineColor,
        barWidth: 2,
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }


  // Additional Function
  double getMinYFromGroup(Map<String, List<FlSpot>> group) {
    if (group.isEmpty) return 0;
    return group.values.expand((list) => list).map((e) => e.y).reduce((a, b) => a < b ? a : b);
  }

  double getMaxYFromGroup(Map<String, List<FlSpot>> group) {
    if (group.isEmpty) return 6;
    return group.values.expand((list) => list).map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }

  List<LineChartBarData> getChartBarsFromGroup(Map<String, List<FlSpot>> group) {
    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    int index = 0;

    return group.entries.map((entry) {
      Color lineColor = colors[index % colors.length];
      deviceColors[entry.key] =lineColor;
      index++;

      return LineChartBarData(
        spots: entry.value,
        isCurved: true,
        color: lineColor,
        barWidth: 2,
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }

  Widget buildLegend(Map<String, List<FlSpot>> group) {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: group.keys.map((deviceId) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: deviceColors[deviceId] ?? Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              deviceId,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Chart", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF28ABEA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: siteId,
                    decoration: const InputDecoration(
                      labelText: "Site ID",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _selectedItems = value;
                      siteId.text = value;
                      _chartGetter();
                    },
                    );
                  },
                  itemBuilder: (context) => _items.map((String value) {
                    return PopupMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        color: Colors.blue,
                      ),
                      height: 47,
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.arrow_drop_down_circle, size: 30, color: Colors.white),
                    ),
                ),
              ],
            ),
            Expanded(
              child: 
               ListView.builder(
                itemCount: chartGroups.length,
                itemBuilder: (context, index) {
                  final group = chartGroups[index];
                  return 
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child:
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                            aspectRatio: 1.7,
                            child: 
                            SizedBox(  
                              height: 300,
                              child: LineChart(
                                LineChartData(
                                  minY: getMinYFromGroup(group),
                                  maxY: getMaxYFromGroup(group),
                                  lineBarsData: getChartBarsFromGroup(group),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          final label = indexToDate[value] ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 12.0),
                                            child: SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              space: 8,
                                              child: Transform.rotate(
                                                angle: -0.8,
                                                child: Text(label, style: TextStyle(fontSize: 10)),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipBgColor: Colors.blueAccent,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((touchedSpot) {
                                          final xValue = touchedSpot.x;
                                          final yValue = touchedSpot.y;
                                          final deviceName = deviceNames[xValue] ?? "Unknown";
                                          return LineTooltipItem(
                                            "$deviceName\nTime: $yValue",
                                            const TextStyle(color: Colors.white),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: buildLegend(group),
                          ),
                        ],
                      ), 
                    );
                },
              ),
            ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Note", style: TextStyle(color: Colors.red),),
                  Text(": press on data chart's spot to examine")
                ],
              ),
          ],
        ),
      ),
    );
  }
}
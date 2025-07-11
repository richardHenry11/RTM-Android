import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rtm/connection/socket_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class RealtimeChart extends StatefulWidget {
  const RealtimeChart({super.key});

  @override
  State<RealtimeChart> createState() => _RealtimeChartState();
}

class _RealtimeChartState extends State<RealtimeChart> {
  final socketService = SocketService();
  final TextEditingController siteId = TextEditingController();
  final List<String> _items = [];
  String? _selectedItems;
  String? _email;

  // Data dari WebSocket
  Map<double, String> xLabels = {};
  Map<String, List<FlSpot>> chartDataMap = {}; // Simpan data tiap device
  Map<double, String> deviceNames = {}; // Untuk tooltip

  // colour saver
  Map<String, Color> deviceColors = {};

  // cached dataMap
  Map<String, Map<String, List<FlSpot>>> chartCache = {};



  void sendMessageToWS() {
    if (_selectedItems == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select site first")),
      );
      return;
    }

    if(chartCache.containsKey(_selectedItems)) {
      setState(() {
        chartDataMap = Map<String, List<FlSpot>>.from(chartCache[_selectedItems]!);
        chartDataMap.clear();
      });
      return;
    }

    // if ther's no caches yet, send request to ws


    // setState(() {
    //   chartDataMap.clear(); // Reset chart saat pindah site
    // });

    Map<String, dynamic> message = {
      "email": _email,
      "site_id": _selectedItems,
    };

    print("📡 Sending message to WebSocket: $message");
    socketService.sendMessage(jsonEncode(message));
  }

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
            chartCache[_selectedItems!] = Map<String, List<FlSpot>>.from(chartDataMap);


            deviceNames[index] = deviceName; // for device name handler
            xLabels[index] = data["start_time"]; // start time handler
          });
        }
      }
    } catch (e, stackTrace) {
      print("❌ Error parsing WebSocket response: $e");
      print(stackTrace);
    }
  }

  List<MapEntry<Map<String, List<FlSpot>>, List<String>>> getGroupedCharts(int groupSize) {
    List<MapEntry<Map<String, List<FlSpot>>, List<String>>> grouped = [];
    int index = 0;
    Map<String, List<FlSpot>> currentGroup = {};
    List<String> currentNames = [];

    for (var entry in chartDataMap.entries) {
      currentGroup[entry.key] = entry.value;
      currentNames.add(entry.key);
      index++;

      if (index % groupSize == 0) {
        grouped.add(MapEntry(currentGroup, currentNames));
        currentGroup = {};
        currentNames = [];
      }
    }

    if (currentGroup.isNotEmpty) {
      grouped.add(MapEntry(currentGroup, currentNames));
    }

    return grouped;
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
        print("WebSocket Disconnected, retrying in 1 seconds...");

        Future.delayed(const Duration(seconds: 1), () {
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

  Future<void> _reader() async {
    if (_email == null) {
      print("⚠️ Email belum dimuat, coba lagi...");
      return;
    }

    print("📡 Menghubungkan ke API...");

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

  List<LineChartBarData> getChartBars(Map<String, List<FlSpot>> groupedMap) {
    return groupedMap.entries.map((entry) {
      final deviceName = entry.key;
      final spots = entry.value;

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: getColorForDevice(deviceName), // <<< LINE WARNA SESUAI DEVICE
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: getColorForDevice(deviceName), // <<< TITIK WARNA SESUAI DEVICE
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      );
    }).toList();
  }

  bool isChartEmpty() {
    return chartDataMap.isEmpty || chartDataMap.values.every((list) => list.isEmpty);
  }

  Color getColorForDevice(String deviceName) {
    if (deviceColors.containsKey(deviceName)) {
      return deviceColors[deviceName]!;
    } else {
      final random = Random(deviceName.hashCode); // random based on device name
      final color = Color.fromARGB(
        255,
        100 + random.nextInt(155),
        100 + random.nextInt(155),
        100 + random.nextInt(155),
      );
      deviceColors[deviceName] = color;
      return color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Realtime Chart", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF28ABEA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ElevatedButton(
            //   onPressed: (){
            //     // button funct
            //     print("cache Data: $chartCache");
            //   },
            //   child: Text("test var")
            // ),

            // Content
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    enabled: false,
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
                      sendMessageToWS();
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
              child: isChartEmpty()
                  ? const Center(
                      child: Text(
                        "Data is not available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: getGroupedCharts(5).map((groupEntry) {
                        final groupedMap = groupEntry.key;
                        final deviceNamesInGroup = groupEntry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Card(
                            elevation: 4,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 250,
                                  child: LineChart(
                                    LineChartData(
                                      minY: getMinY(),
                                      maxY: getMaxY(),
                                      lineBarsData: getChartBars(groupedMap),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 50,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              String label = xLabels[value] ?? '';
                                              if (label.isNotEmpty) {
                                                try {
                                                  DateTime time = DateTime.parse(label);
                                                  String formatted = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
                                                  return SideTitleWidget(
                                                    axisSide: meta.axisSide,
                                                    child: Text(
                                                      formatted,
                                                      style: const TextStyle(fontSize: 10),
                                                    ),
                                                  );
                                                } catch (_) {}
                                              }
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: const Text(""),
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
                                        handleBuiltInTouches: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: deviceNamesInGroup.map((name) {
                                    return Chip(
                                      avatar: CircleAvatar(
                                        backgroundColor: getColorForDevice(name),
                                      ),
                                      label: Text(
                                        name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.grey[300],
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Note",
                  style: TextStyle(color: Colors.red),
                ),
                Text(": press on data chart's spot to examine"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
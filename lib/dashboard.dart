import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rtm/connection/socket_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final socketService = SocketService();
  final TextEditingController _controller = TextEditingController();
  final List<String> _items = [];
  String? _selectedItems;
  String? _email;

  // Data from websocket
  List<String> devicesId = [];
  List<String> devicesName = [];

  Map<String, String> deviceStatus = {}; // key: device_id, Value: running_time
  Map<String, String> deviceTimeStart = {};

  void sendMessageToWS() {
    if (_selectedItems == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("select site first")),
      );
      return;
    }

    Map<String, dynamic> message = {
      "email": _email,
      "site_id": _selectedItems,
    };

    print("📡 Sending message to WebSocket: $message");
    socketService.sendMessage(jsonEncode(message));
  }

  void _handleWebsocketResponse(dynamic message) {
  try {
    print("parsing Websocket Response...");
    Map<String, dynamic> data = jsonDecode(message);
    print("parsed JSON: $data");

    if (data.containsKey("status") && data["status"] == "Running") {
      setState(() {
        String deviceId = data["device_id"].toString();
        String deviceName = data["device_name"].toString();

        // Cek apakah deviceId sudah ada
        if (!devicesId.contains(deviceId)) {
          devicesId.add(deviceId);
          devicesName.add(deviceName);
        }

        // Update status dan waktu
        deviceStatus[deviceId] = data["running_time"].toString();
        deviceTimeStart[deviceId] = data["start_time"].toString();
      });
    } else {
        print("📥 Device list received (no 'status' key)");

        List<dynamic> deviceIds = data["device_id"] ?? [];
        List<dynamic> deviceNames = data["device_name"] ?? [];

        int minLength = [deviceIds.length, deviceNames.length].reduce((a, b) => a < b ? a : b);

        setState(() {
          for (int i = 0; i < minLength; i++) {
            String deviceId = deviceIds[i]?.toString() ?? "Unknown";
            String deviceName = deviceNames[i]?.toString() ?? "Unknown";

            if (!devicesId.contains(deviceId)) {
              devicesId.add(deviceId);
              devicesName.add(deviceName);
            }

            // Set status default jika belum pernah jalan
            deviceStatus[deviceId] = deviceStatus[deviceId] ?? "00:00:00";
          }
        });
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

        Future.delayed(Duration(seconds: 5), () {
          if (mounted && socketService.status != "connected") {
            print("🔄 Attempting to reconnect...");
            socketService.connect();
          }
          isReconnecting = false;
        });
      }
    };

    socketService.connect();
    // socketService.onMessageReceived = _handleWebsocketResponse;
    // Tangani pesan dari WebSocket
  socketService.onMessageReceived = (message) {
    print("🛜 WebSocket Message: $message"); // Debug log
    _handleWebsocketResponse(message);
  };
  }

  Future<void> _loadEmail() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      _email = pref.getString('email') ?? 'null';
      print(_email);
    });
    await _reader();
  }

  Future<void> _reader() async {
    if (_email == null) {
      print("⚠️ Email belum dimuat, coba lagi...");
      return;
    }

    print("email sekarang: $_email");

    print("📡 Menghubungkan ke API...");

    final response = await http.post(
      Uri.parse('https://rtm.envilife.co.id/api/data'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _email, 'type': 'site_id'}),
    );

    print("🛜 Response API: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ Data diterima: $data");

      if (data['site_id'] != null) {
        setState(() {
          _items.clear();
          _items.addAll(List<String>.from(data['site_id']));
        });
        print("📌 Updated dropdown items: $_items"); // Debug log
      } else {
        print("❌ Failed to fetch data. Response: ${response.body}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Realtime Monitoring", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF28ABEA),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Real Time Monitoring",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Optional Buttons for device getter

          // Padding(
          //   padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       ElevatedButton(
          //         style: ElevatedButton.styleFrom(
          //             shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(5)),
          //                 backgroundColor: Colors.blue,
          //                 minimumSize: Size(
          //                   MediaQuery.of(context).size.width * 0.45, 
          //                   MediaQuery.of(context).size.height * 0.057
          //                 ),
          //               ),
          //         onPressed: () {
          //           _reader();
          //         },
          //         child: Text("Show Devices List", style: TextStyle(color: Colors.white),),
          //       ),
          //       ElevatedButton(
          //         style: ElevatedButton.styleFrom(
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(5)
          //           ),
          //           minimumSize: Size(
          //             MediaQuery.of(context).size.width * 0.45, 
          //             MediaQuery.of(context).size.height * 0.057
          //           ),
          //           backgroundColor: Colors.green
          //         ),
          //         onPressed: sendMessageToWS,
          //         child: Text("Get Devices", style: TextStyle(color: Colors.white),),
          //       ),
          //     ],
          //   ),
          // ),

          
          Stack(
            children: [
              TextFormField(
                enabled: false,
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              Positioned(
                right: 0,
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                  onSelected: (String value) {
                    setState(() {
                      _controller.text = value;
                      _selectedItems = value;

                      // Bersihkan data device sebelumnya
                      devicesId.clear();
                      devicesName.clear();
                      deviceStatus.clear();
                      deviceTimeStart.clear();

                      // Kirim site_id baru ke WebSocket
                      sendMessageToWS();
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _items.map((String item) {
                      return PopupMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ),
          Expanded(
  child: devicesId.isEmpty
      ? Center(child: Text("No Devices Available"))
      : ListView.builder(
          itemCount: devicesId.length,
          itemBuilder: (context, index) {
            String deviceId = devicesId[index];
            String runningTime = deviceStatus[deviceId] ?? "00:00:00";
            String deviceName = devicesName[index];
            String startTime = deviceTimeStart[deviceId] ?? "2000-04-11 02:32:05";

            bool isRunning = deviceStatus.containsKey(deviceId) && runningTime != "00:00:00";

            return Card(
              margin: EdgeInsets.all(8.0),
              elevation: 4,
              color: isRunning ? Colors.blue : Colors.white, // Warna card berdasarkan status
              child: ListTile(
                title: Text(
                  deviceName,
                  style: TextStyle(color: isRunning ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   "ID: $deviceId",
                    //   style: TextStyle(color: isRunning ? Colors.white : Colors.black),
                    // ),
                    Text(
                      "Start Time: $startTime",
                      style: TextStyle(color: isRunning ? Colors.white : Colors.black),
                    ),
                    Text(
                      "Running Time: $runningTime",
                      style: TextStyle(color: isRunning ? Colors.white : Colors.black),
                    ),
                  ],
                ),
                leading: Icon(Icons.devices, color: isRunning ? Colors.white : Colors.blue),
              ),
            );
          },
        ),
      )

        ],
      ),
    );
  }
}

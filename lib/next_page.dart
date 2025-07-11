import 'package:flutter/material.dart';
import 'package:rtm/main.dart';
import 'package:rtm/connection/socket_service.dart';

class NextPage extends StatefulWidget {
  const NextPage({super.key});

  @override
  State<NextPage> createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  final socketService = SocketService();
  bool isNavigating = false; // avoiding looping navigation

  @override
  void initState() {
    super.initState();

    socketService.onStatusChange = (status) {
      print("🔥 Status diterima di NextPage: $status");

      if (status == "OFF" && !isNavigating) {
        isNavigating = true;
        Future.delayed(Duration.zero, () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          }
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Well Done! Coki"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Text("Congrats! Anda sekarang bisa berkomunikasi dengan WebSocket"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                ),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
              },
              child: Text("Home", style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}

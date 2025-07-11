import 'dart:io';

class SocketService {
  WebSocket? _socket;
  bool _isConnected = false;

  String get status => _isConnected ? "connected" : "disconnected";

  Function(String)? onStatusChange;
  Function(String)? onMessageReceived;

  void sendMessage(String message){
    if (_socket != null) {
      _socket!.add(message);
      print("Data Sent: $message");
    } else {
      print("WS belum tersambung!");
    }
  }

  void connect({int retryCount = 0}) async {
    try {
      _socket = await WebSocket.connect("wss://rtm.envilife.co.id/ws");
      _isConnected = true;
      onStatusChange?.call("connected");

      _socket!.listen(
        (data) {
          print("📩 Data received: $data");
          // websocket message handler
          if (onMessageReceived != null) {
            onMessageReceived!(data);
          }
        },
        onDone: () {
          print("❌ WebSocket Disconnected");
          _isConnected = false;
          onStatusChange?.call("disconnected");
        },
        onError: (error) {
          print("⚠️ WebSocket Error: $error");
          _isConnected = false;
          onStatusChange?.call("disconnected");
        },
      );
    } catch (e) {
      print("🚨 Connection failed: $e");
      _isConnected = false;
      onStatusChange?.call("disconnected");
      // onConnectionFailed?.call();

       // Tambahkan retry dengan delay 5 detik
      if (retryCount < 5) {
        print("🔁 Mencoba reconnect dalam 5 detik...");
        await Future.delayed(Duration(seconds: 5));
        connect(retryCount: retryCount + 1);
      } else {
        print("🛑 Gagal koneksi setelah $retryCount kali");
        onConnectionFailed?.call();
      }
    }
  }

  Function()? onConnectionFailed;

  void disconnect() {
  _socket?.close();
  _isConnected = false; // Ubah nilai _isConnected, bukan status
  onStatusChange?.call("disconnected");
  }
  } 
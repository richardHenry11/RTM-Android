import 'package:flutter/material.dart';
import 'package:rtm/weeklyChart.dart';
import 'package:rtm/dailyChart.dart';
import 'package:rtm/dailyChart.dart';
import 'package:rtm/dashboard.dart';
import 'package:rtm/data.dart';
import 'package:rtm/monthlyChart.dart';
import 'package:rtm/raw_data.dart';
import 'package:rtm/realtime_chart.dart';
import 'package:rtm/regist.dart';
import 'package:rtm/userReg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'package:rtm/connection/socket_service.dart';
import 'dart:async';
import 'dashboard.dart';
import 'package:rtm/shaping/trapezium.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'main.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();// harus pertama
    await findSystemLocale();
    await initializeDateFormatting();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(Duration(seconds: ));

    runApp(MyApp(isLoggedIn: isLoggedIn));
  }, (error, stackTrace) {
    debugPrint('Caught error in release: $error');
  });
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? MainPage() : LoginPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final socketService = SocketService();
  bool _isloadloading = false;
  bool _hasNavigated = false;
  Timer? snackbarTimer;
  bool _isAnimated = true;
  String _currentTime = "";
  Timer? _timer;
  String? _savedEmail = "Loading...";
  String? _savedName = "Loading...";

@override
void initState() {
  super.initState();
  _loadEmail();
  print("📡 inittialization websocket...");

  socketService.onStatusChange = (status) {
    print("🛜 WebSocket Status: $status");

    if (!mounted) return; // make sure widget is still there b4 UI

    if (status == "connected") {
      print("connected to websocket");
    } else {
      print("disconnected");
    }
  };

  // call websocket connection
  socketService.onConnectionFailed = () {
    // logout if disconnected
    print("🧯 Connection permanently failed. Logout...");
    _logout();
  };

  socketService.connect();

   _updateTime(); // Panggil pertama kali
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted){
        _updateTime();
      } else (){
        timer.cancel();
      };
    });
}

  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedEmail = prefs.getString('email') ?? "Tidak ada email tersimpan";
      _savedName = prefs.getString('name') ?? "tidak ada nama tersimpan";
    });
  }


  void _updateTime (){
    final now = DateTime.now();
    final String formattedTime = DateFormat('HH:mm:ss, EEEE, d MMMM').format(now);
    // print("format waktu berhasil muncul di log: $formattedTime");

    if (mounted) {
      setState(() {
      _currentTime = formattedTime;
    });
    }
  }

  void _showChartHistory (){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: 
          Center(
            child: Text(
              "Chart History", style: TextStyle(
                color: Colors.green
              ),
            ),
          ),
          content:
          SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.4,
          child:
          SingleChildScrollView(
            child: 
            Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.00),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    minimumSize: Size(
                      MediaQuery.of(context).size.width * 0.8, 
                      MediaQuery.of(context).size.height * 0.058
                    ),
                    backgroundColor: Color(0xFF28ABEA)
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => ChartDaily())
                    );
                  }, 
                  child: Text("Daily", style: TextStyle(color: Colors.white),)
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  minimumSize: Size(
                    MediaQuery.of(context).size.width * 0.8, 
                    MediaQuery.of(context).size.height * 0.058
                  ),
                  backgroundColor: Color(0xFF28ABEA)
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => ChartWeekly())
                  );
                }, 
                child: Text("Weekly", style: TextStyle(color: Colors.white))
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    minimumSize: Size(
                      MediaQuery.of(context).size.width * 0.8, 
                      MediaQuery.of(context).size.height * 0.058
                    ),
                    backgroundColor: Color(0xFF28ABEA)
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => Monthlychart())
                    );
                  }, 
                  child: Text("Monthly", style: TextStyle(color: Colors.white))
                ),
              )
            ],
          ),
          ) 
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
              backgroundColor: Color.fromARGB(255, 255, 42, 0)
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("back", style: TextStyle(color: Colors.white)),
          ),
        ],
        );
      }
    );
  }

  void _showDialogregist (){
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: 
        Center(child: Text("Registration", style: TextStyle(color: Color(0xFF28ABEA)),)),
        content: 
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.00),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    minimumSize: Size(
                      MediaQuery.of(context).size.width * 0.8, 
                      MediaQuery.of(context).size.height * 0.058
                    ),
                    backgroundColor: Color(0xFF28ABEA)
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => Register())
                    );
                  }, 
                  child: Text("Regist Device", style: TextStyle(color: Colors.white),)
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  minimumSize: Size(
                    MediaQuery.of(context).size.width * 0.8, 
                    MediaQuery.of(context).size.height * 0.058
                  ),
                  backgroundColor: Color(0xFF28ABEA)
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => userReg())
                  );
                }, 
                child: Text("Regist User", style: TextStyle(color: Colors.white))
              )
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
              backgroundColor: Color.fromARGB(255, 255, 42, 0)
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("back", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
  }

  Future<void> _logout() async {
    setState(() {
      _isloadloading = true;
    });

    String email = "email";
    String password = "password";
    String logout = "logout";

    final response = await http.post(
      Uri.parse('https://rtm.envilife.co.id/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'type': logout}),
    );

    setState(() {
      _isloadloading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'Logged out') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Menghapus semua data user agar lebih bersih

        print(response.body);
        print("Logout successful");

        if (!context.mounted) return; // Pastikan context masih ada sebelum navigasi

        // Pindah ke halaman login tanpa bisa kembali
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    snackbarTimer?.cancel(); // Hentikan timer saat widget dispose
    super.dispose();
    socketService.disconnect();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: 
      PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.sizeOf(context).height * 0.1045), 
        child:
          AppBar(
        backgroundColor: Color(0xFF28ABEA),
        title: Image.asset('assets/logo.png', height: 40, width: 200,),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white,),
            onPressed: _logout,
          )
        ],
        ), 
        ),
      body:
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.861,
        child: Container(
          decoration: 
          BoxDecoration(
            image: DecorationImage(
              image: 
                AssetImage("assets/bg.png"),
              fit: BoxFit.cover,
            )
          ),
          child:
          SingleChildScrollView(
            child: 
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Column(
                          children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: 
                  Row(
                  children: [
                    SizedBox(
                      height: 48,
                      child: ClipPath(
                        // clipper: TrapeziumClipper(),
                        child: ElevatedButton(onPressed: (){
                        Navigator.push(context, 
                          MaterialPageRoute(builder: (context) => Dashboard())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        )
                        ),
                        backgroundColor: Color(0xFF28ABEA),
                      ),
                      child: Text("Realtime reader", style: TextStyle(color: Colors.white),)
                      ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ClipPath(
                        // clipper: TrapeziumClipper(),
                        child: ElevatedButton(onPressed: (){
                        Navigator.push(context, 
                          MaterialPageRoute(builder: (context) => RealtimeChart())
                        );
                      },
                      
                     style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        )
                        ),
                        backgroundColor: Color(0xFF28ABEA)
                      ),
                      child: Text("Realtime Chart", style: TextStyle(color: Colors.white),)
                      ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ClipPath(
                        // clipper: TrapeziumClipper(),
                        child: ElevatedButton(
                          onPressed: (){
                            // logic button here!
                            _showChartHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        )
                        ),
                        backgroundColor: Color(0xFF28ABEA)
                      ),
                      child: Text("Chart History", style: TextStyle(color: Colors.white),)
                      ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 48,
                      child: ClipPath(
                        // clipper: TrapeziumClipper(),
                        child: ElevatedButton(onPressed: (){
                        Navigator.push(context, 
                          MaterialPageRoute(builder: (context) => Data())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        )
                        ),
                        backgroundColor: Color(0xFF28ABEA)
                      ),
                      child: Text("Data", style: TextStyle(color: Colors.white),)
                      ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 48,
                      child: ClipPath(
                        // clipper: TrapeziumClipper(),
                        child: ElevatedButton(onPressed: (){
                        Navigator.push(context, 
                          MaterialPageRoute(builder: (context) => RawData())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        )
                        ),
                        backgroundColor: Color(0xFF28ABEA)
                      ),
                      child: Text("Raw Data", style: TextStyle(color: Colors.white),)
                      ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 48,
                      child: ClipPath(
                        // clipper: TrapeziumClipper(),
                        child: ElevatedButton(onPressed: (){
                        // Navigator.push(context, 
                        //   MaterialPageRoute(builder: (context) => Register())
                        // );
                        _showDialogregist();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        )
                        ),
                        backgroundColor: Color(0xFF28ABEA)
                      ),
                      child: Text("Register", style: TextStyle(color: Colors.white),)
                      ),
                      ),
                    ),
                  ],
                ),
                ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentTime, // Menampilkan waktu real-time
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 20, // Perbesar ukuran teks
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.225),
                        Center(
                          child: 
                          Row(
                            children: [
                              SizedBox(width: MediaQuery.sizeOf(context).width * 0.3,),
                              // AnimatedTextKit(
                              //   animatedTexts:[
                              //     TypewriterAnimatedText(
                              //       "Welcome to",
                              //       textStyle: TextStyle(color: Colors.yellowAccent, fontSize: 30),
                              //       speed: Duration(milliseconds: 100)
                              //     ),
                              //   ],
                              //   totalRepeatCount: 1,
                              //   pause: Duration(milliseconds: 500),
                              //   onFinished: () {
                              //     setState(() {
                              //       _isAnimated = false;
                              //     });
                              //   },
                              //   ),
                            ],
                          ),
                        ),
                        Center(
                          child: 
                          Row(
                            children: [
                              SizedBox(width: MediaQuery.sizeOf(context).width * 0.2,),
                              AnimatedTextKit(
                                animatedTexts:[
                                  TypewriterAnimatedText(
                                    "Runtime Monitor",
                                    textStyle: TextStyle(color: Colors.yellowAccent, fontSize: 30),
                                    speed: Duration(milliseconds: 100)
                                  ),
                                ],
                                totalRepeatCount: 1,
                                pause: Duration(milliseconds: 500),
                                onFinished: () {
                                  setState(() {
                                    _isAnimated = false;
                                  });
                                },
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                         Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  "Welcome, ", style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text("$_savedName 😊", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                        ),
                      ],
                    ),
                  )
                          ],
                        ),
              ),
            ) 
          ),
      )
    );
  }
}
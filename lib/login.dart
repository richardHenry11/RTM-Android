import 'package:flutter/material.dart';
// import 'dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKeyReg = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    String email = _usernameController.text;
    String password = _passwordController.text;
    String login = "login";

    final response = await http.post(
      Uri.parse('https://rtm.envilife.co.id/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'type':login}),
    )
    .timeout(Duration(seconds: 10));

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['status'] == 'OK' && data['role'] == 'admin') {
        print("Login Successful, Role: ${data['role']}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Berhasil!"),
            backgroundColor: Colors.green,
          ),
        );

        // Save Login Data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', data['role']);
        await prefs.setString('name', data['name']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('email', email);

        // Move to dashboard 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Failed: ${data['status']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed to connect to server")),
      );
    }
  }

  void _showDialogValidation (){
    SnackBar(
      content: Text("please fill the login credentials")
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF28ABEA),
      body:    
      SingleChildScrollView(
        child:
        Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            // Text("Logo CBI", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
            Image.asset('assets/logo.png', height: 70, width: 200,),
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.075,),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Card(
                color: const Color.fromARGB(255, 117, 117, 117),
                child: 
                Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Runtime Monitor", style: TextStyle(color: const Color.fromARGB(255, 224, 224, 224), fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(
                      height: 50,
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                      Form(
                      key: _formKeyReg,
                      child: 
                      Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty){
                                 return 'email must be filled';
                              } else if (!value.contains('@')) {
                                return "email must contains '@'";
                              }
                            },
                            decoration: InputDecoration(
                                        hintText: "Email",
                                        hintStyle: TextStyle(color: const Color.fromARGB(255, 195, 195, 195)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius: BorderRadius.circular(10)
                                        ), 
                                        filled: true,
                                        fillColor: Colors.white      
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                              if (value == null || value.isEmpty){
                                 return 'password must be filled';
                              }
                            },
                        obscureText: true,
                        decoration: InputDecoration(hintText: "Password",
                                    hintStyle: TextStyle(color: const Color.fromARGB(255, 195, 195, 195)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10)
                                    ), 
                                    filled: true,
                                    fillColor: Colors.white      
                        ),
                      ),
                        ],
                      )  
                    ),
                    // Container(
                    //   padding: EdgeInsets.symmetric(horizontal: 10),
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    //   child: 
                      
                    // ) 
                    ),
                    SizedBox(height: 50),
                    _isLoading
                        ? CircularProgressIndicator()
                        : 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: SizedBox(
                            height: 60,
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                onPressed:(){
                                if (_formKeyReg.currentState!.validate()){
                                  _login();
                                } else {
                                  _showDialogValidation();
                                }
                                },
                                child: Text("Login", style: TextStyle(color: Colors.white, fontSize: 20),),
                            ),
                          ),
                        ),
                  ],
                ),
              ), 
              ),
            ),
          ],
        ),
      )
      )
    );
  }
}

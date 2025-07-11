  import 'dart:convert';
  import 'package:flutter/material.dart';
  import "package:http/http.dart" as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:async';

class userReg extends StatefulWidget {
  const userReg({super.key});

  @override
  State<userReg> createState() => _userRegState();
}

class _userRegState extends State<userReg> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _userEmail = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _rePassword = TextEditingController();
  final List<String> itemsRole = ['user','admin','super admin']; 
  String? _selectedValue;
  String? _email;

  void registration() async {
    if(_email == null){
      print("email belum dimuat");
    }

    print("regist page connecting to API...");

    final response = await http.post(
      Uri.parse("https://rtm.envilife.co.id/api/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email':_userEmail.text, 'password':_password.text, 'name':_fullName.text, 'role':_selectedValue, 'type':'signup'})
    );

    print("Response API: ${response.statusCode}");

    if(response.statusCode == 200) {
      _showDialogSuccess();
    } else {
      print("registration failed.. Status : ${response.statusCode}");
      _showDialogError();
    }
  }

    void _showDialogError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("registration Failed"),
          content: Text("Account has failed been added"),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                backgroundColor: const Color.fromARGB(255, 255, 60, 0)
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  void _showDialogSuccess() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("registration successful"),
        content: 
        Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50,),
            Text("Account has successfully been added"),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
              backgroundColor: Colors.green
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK", style: TextStyle(color: Colors.white),),
          ),
        ],
      );
    },
  );
}

  void _showDialogValidation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            "Form Invalid!",
            style: TextStyle(color: Colors.red),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // ❗ for card to not fulling screen
          children: [
            Icon(
              Icons.close,
              size: 50.0,
              color: Colors.red,
            ),
            SizedBox(height: 10),
            Center(child: Text("Please fill the form's credentials correctly 😊.")),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Registration", style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF28ABEA),
      ),
      body:
      SingleChildScrollView(
        child: 
      Container(
          child:
            Center(
              child: 
              Form(
                key: _formKey,
                child: 
                  Column(
                children: [
                  Image.asset("assets/vector.png", 
                    width: MediaQuery.of(context).size.width * 0.7, 
                    height: MediaQuery.of(context).size.height * 0.3,),
                  Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                      child: TextFormField(
                        enabled: true,
                        controller: _fullName,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Full Name must be filled!';
                          }
                          return null;
                        },
                    ),
                  ),
                ),
  
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                      child: TextFormField(
                        enabled: true,
                        controller: _userEmail,
                        decoration: InputDecoration(
                          labelText: "Enter your Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Email must be filled!';
                          } else if (!value.contains('@')) {
                            return 'Email invalid';
                          }
                          return null;
                        },
                    ),
                  ),
                ),
              
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                      child: TextFormField(
                        enabled: true,
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        obscureText: true,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Password must be filled!';
                          }
                          return null;
                        },
                    ),
                  ),
                ),
              
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                      child: TextFormField(
                        enabled: true,
                        controller: _rePassword,
                        decoration: InputDecoration(
                          labelText: "Re-type Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        obscureText: true,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'please re-type password must be filled!';
                          } else if (_rePassword.text != _password.text){
                            return "re-password doesn't match";
                          }
                          return null;
                        },
                    ),
                  ),
                ),
              
                Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: DropdownButtonFormField<String>(
                      value: _selectedValue,
                      validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Choose one of the options!';
                          }
                          return null;
                        },
                      hint: Text("Pilih Status"),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white, // Warna latar belakang
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25), // Mengubah border menjadi lonjong
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      items: itemsRole.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedValue = newValue;
                          print(_selectedValue);
                        });
                      },
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    minimumSize: Size(
                      MediaQuery.of(context).size.width * 0.9, 
                      MediaQuery.of(context).size.height * 0.058
                    ),
                    backgroundColor: Color(0xFF28ABEA)
                  ),
                    onPressed: (){
                      // button func here!
                      if (_formKey.currentState!.validate()){
                        registration();
                      } else {
                        _showDialogValidation();
                      }
                    }, 
                    child: Text("Sign Up", style: TextStyle(color: Colors.white),
                    )
                  )
                ],
              ),
              )
            )
        )
      )
    );
  }
}